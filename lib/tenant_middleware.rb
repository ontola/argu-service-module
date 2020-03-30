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
      return tenant_is_missing(request) unless ActsAsTenant.current_tenant
      return redirect_correct_iri_prefix(request.url) if wrong_iri_prefix?(request)

      rewrite_path(env, request)
    else
      Apartment::Tenant.switch!('public')
    end

    I18n.locale = I18n.default_locale

    call_app(env)
  end

  private

  def call_app(env)
    status, headers, response = @app.call(env)

    headers['Manifest'] = "#{ActsAsTenant.current_tenant.iri}/manifest.json" if ActsAsTenant.current_tenant

    [status, headers, response]
  end

  def fallback_location
    "#{Rails.application.config.origin}/argu"
  end

  def log_tenant
    if ActsAsTenant.current_tenant
      Rails.logger.debug "Tenant: #{ActsAsTenant.current_tenant.url}"
    else
      Rails.logger.debug 'No tenant found'
    end
  end

  def rewrite_path(env, request)
    return if ActsAsTenant.current_tenant.nil? || ActsAsTenant.current_tenant.iri_prefix == request.host

    env['PATH_INFO'].gsub!(
      %r{((#{ActsAsTenant.current_tenant.iri.path}|\/#{ActsAsTenant.current_tenant.uuid}))(\/|$)}i,
      '/'
    )
  end

  def redirect_correct_iri_prefix(requested_url)
    url = ActsAsTenant.current_tenant.url.downcase
    iri = ActsAsTenant.current_tenant.iri
    location = requested_url
                 .downcase
                 .sub("#{Rails.application.config.frontend_url}/#{url}", iri)
                 .sub("#{Rails.application.config.origin}/#{url}", iri)
    [301, {'Location' => location, 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
  end

  def tenant_is_missing(request)
    if request.url.chomp('/') == Rails.application.config.origin
      [301, {'Location' => fallback_location, 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
    else
      [404, {'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
    end
  end

  def tenantize(env, request)
    return false unless tenantized_url?(env)

    ActsAsTenant.current_tenant = TenantFinder.from_request(request)

    log_tenant

    true
  end

  def tenantized_url?(env)
    !env['PATH_INFO'].start_with?(['', Rails.application.routes.default_scope, '_public', ''].compact.join('/'))
  end

  def wrong_iri_prefix?(request)
    ![URI(request.url).host, URI(request.url).path].join('').starts_with?(ActsAsTenant.current_tenant.iri_prefix)
  end
end
