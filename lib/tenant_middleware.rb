# frozen_string_literal: true

require_relative '../app/helpers/jwt_helper'

class TenantMiddleware
  include JWTHelper

  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    if tenantize(env, request)
      return tenant_is_missing unless ActsAsTenant.current_tenant
      return redirect_correct_iri_prefix(request.url) if wrong_iri_prefix?(request)

      rewrite_path(env, request)
    else
      switch_to_public
    end

    I18n.locale = I18n.default_locale

    call_app(env)
  end

  private

  def call_app(env)
    status, headers, response = @app.call(env)

    headers['Manifest'] = "#{ActsAsTenant.current_tenant.iri}/manifest.json" if ActsAsTenant.current_tenant
    headers['X-API-Version'] = VERSION

    [status, headers, response]
  end

  def default_oauth_route?(request)
    return true if request.url.starts_with?("#{Rails.application.config.origin}/oauth")

    return false unless LinkedRails::Constraints::Whitelist.matches?(request)

    request.path.starts_with?('/oauth')
  end

  def log_tenant
    if ActsAsTenant.current_tenant
      Rails.logger.debug "Tenant: #{ActsAsTenant.current_tenant.iri}"
    else
      Rails.logger.debug 'No tenant found'
    end
  end

  def request_path_starts_with?(env, path)
    scoped_path = ['', Rails.application.routes.default_scope, path, ''].compact.join('/')

    env['PATH_INFO'].start_with?(scoped_path)
  end

  def rewrite_path(env, request)
    return if ActsAsTenant.current_tenant.nil? || ActsAsTenant.current_tenant.iri_prefix == request.host

    env['PATH_INFO'].gsub!(
      %r{((#{ActsAsTenant.current_tenant.iri.path}|/#{ActsAsTenant.current_tenant.uuid}))(/|$)}i,
      '/'
    )
  end

  def redirect_correct_iri_prefix(requested_url)
    url = shortname_in_url(requested_url)
    iri = defined?(Shortname) ? Shortname.find_resource(url).iri : ActsAsTenant.current_tenant.iri
    location = requested_url.downcase.sub("#{Rails.application.config.origin}/#{url.downcase}", iri)
    [301, {'Location' => location, 'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
  end

  def shortname_in_url(url)
    ActsAsTenant.current_tenant.all_shortnames.detect do |shortname|
      url.downcase.include?("#{Rails.application.config.origin}/#{shortname.downcase}")
    end
  end

  def switch_to_public
    ActsAsTenant.current_tenant = nil
    Apartment::Tenant.switch!('public')
  end

  def tenant_is_missing
    [404, {'Content-Type' => 'text/html', 'Content-Length' => '0'}, []]
  end

  def tenantize(env, request)
    return false unless tenantized_url?(env, request)

    ActsAsTenant.current_tenant = TenantFinder.from_request(request)

    log_tenant

    true
  end

  def tenantized_url?(env, request)
    return false if default_oauth_route?(request)

    %w[_public .well-known].none? do |path|
      request_path_starts_with?(env, path)
    end
  end

  def wrong_iri_prefix?(request)
    ![URI(request.url).host, URI(request.url).path].join('').starts_with?(ActsAsTenant.current_tenant.iri_prefix)
  end
end
