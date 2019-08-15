# frozen_string_literal: true

require_relative '../app/helpers/jwt_helper'

class TenantMiddleware
  include JWTHelper

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    fallback = 'public'

    if tenantized_url?(env)
      tenantize(env, request)

      return tenant_is_missing(request) if tenant_missing?
      return redirect_to_new_frontend(request) if redirect_to_new_frontend?(request)

      fallback = 'argu'
    end

    I18n.locale = I18n.default_locale

    call_app(env, fallback)
  end

  private

  def call_app(env, fallback)
    Apartment::Tenant.switch(ActsAsTenant.current_tenant&.database_schema || fallback) do
      log_tenant

      @app.call(env)
    end
  end

  def fallback_location
    "#{Rails.application.config.frontend_url}/argu"
  end

  def log_tenant
    fe = RequestStore.store[:old_frontend] ? 'old' : 'new'
    schema = Apartment::Tenant.current
    if ActsAsTenant.current_tenant
      Rails.logger.debug "Tenant: #{ActsAsTenant.current_tenant.url}. Frontend: #{fe}. Schema: #{schema}"
    else
      Rails.logger.debug "No tenant found. Frontend: #{fe}. Schema: #{schema}"
    end
  end

  def old_frontend?(env)
    env['HTTP_AUTHORIZATION'].blank? || !decode_token(env['HTTP_AUTHORIZATION'][7..-1])['scopes'].include?('afe')
  rescue JWT::DecodeError
    true
  end

  def redirect_to_new_frontend?(request)
    tenant = ActsAsTenant.current_tenant
    tenant&.use_new_frontend && !request.url.include?("://#{tenant.iri_prefix}")
  end

  def redirect_to_new_frontend(request)
    tenant = ActsAsTenant.current_tenant
    old = [Rails.application.config.host_name, tenant.url].join('/')
    new = tenant.iri_prefix
    [301, {'Location' => request.url.sub(old, new), 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
  end

  def rewrite_path(env, request)
    return if ActsAsTenant.current_tenant.nil? || ActsAsTenant.current_tenant.iri_prefix == request.host

    env['PATH_INFO'].gsub!(%r{(\/(#{ActsAsTenant.current_tenant.url}|#{ActsAsTenant.current_tenant.uuid}))(\/|$)}i, '')
  end

  def tenant_is_missing(request)
    if request.url.chomp('/') == Rails.application.config.frontend_url
      [301, {'Location' => fallback_location, 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
    else
      [404, {'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
    end
  end

  def tenant_missing?
    ActsAsTenant.current_tenant.blank? && !RequestStore.store[:old_frontend]
  end

  def tenantize(env, request)
    ActsAsTenant.current_tenant = TenantFinder.from_request(request)

    RequestStore.store[:old_frontend] = old_frontend?(env)

    rewrite_path(env, request)
  end

  def tenantized_url?(env)
    !env['PATH_INFO'].start_with?('/_public/')
  end
end
