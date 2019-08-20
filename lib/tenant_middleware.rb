# frozen_string_literal: true

require_relative '../app/helpers/jwt_helper'

class TenantMiddleware
  include JWTHelper

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    if tenantize(env, request)
      return tenant_is_missing(request) unless ActsAsTenant.current_tenant || handle_missing_tenant
      return redirect_to_new_frontend(request) if redirect_to_new_frontend?(request)

      rewrite_path(env, request)
    else
      Apartment::Tenant.switch!('public')
    end

    I18n.locale = I18n.default_locale

    @app.call(env)
  end

  private

  def fallback_location
    "#{Rails.application.config.frontend_url}/argu"
  end

  def handle_missing_tenant
    return false unless RequestStore.store[:old_frontend]

    Apartment::Tenant.switch!('argu')
    true
  end

  def log_tenant
    fe = RequestStore.store[:old_frontend] ? 'old' : 'new'
    if ActsAsTenant.current_tenant
      Rails.logger.debug "Tenant: #{ActsAsTenant.current_tenant.url}. Frontend: #{fe}"
    else
      Rails.logger.debug "No tenant found. Frontend: #{fe}"
    end
  end

  def old_frontend?(env)
    env['HTTP_AUTHORIZATION'].blank? || !decode_token(env['HTTP_AUTHORIZATION'][7..-1])['scopes'].include?('afe')
  rescue JWT::DecodeError
    true
  end

  def redirect_to_new_frontend?(request)
    tenant = ActsAsTenant.current_tenant
    RequestStore.store[:old_frontend] && tenant&.use_new_frontend && !request.url.include?("://#{tenant.iri_prefix}")
  end

  def redirect_to_new_frontend(request)
    tenant = ActsAsTenant.current_tenant
    old = [Rails.application.config.host_name, tenant.url].join('/')
    new = tenant.iri_prefix
    [301, {'Location' => request.url.sub(old, new), 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
  end

  def rewrite_path(env, request)
    return if ActsAsTenant.current_tenant.nil? || ActsAsTenant.current_tenant.iri_prefix == request.host

    env['PATH_INFO'].gsub!(%r{(\/(#{ActsAsTenant.current_tenant.url}|#{ActsAsTenant.current_tenant.uuid}))(\/|$)}i, '/')
  end

  def tenant_is_missing(request)
    if request.url.chomp('/') == Rails.application.config.frontend_url
      [301, {'Location' => fallback_location, 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
    else
      [404, {'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
    end
  end

  def tenantize(env, request)
    return false unless tenantized_url?(env)

    ActsAsTenant.current_tenant = TenantFinder.from_request(request)

    RequestStore.store[:old_frontend] = old_frontend?(env)

    log_tenant

    true
  end

  def tenantized_url?(env)
    !env['PATH_INFO'].start_with?('/_public/')
  end
end
