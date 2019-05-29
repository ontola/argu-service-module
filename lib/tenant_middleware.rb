# frozen_string_literal: true

require_relative '../app/helpers/jwt_helper'

class TenantMiddleware
  include JWTHelper

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    ActsAsTenant.current_tenant = TenantFinder.from_request(request)
    Rails.logger.debug ActsAsTenant.current_tenant ? "Tenant: #{ActsAsTenant.current_tenant.url}" : 'No tenant found'
    return redirect_to_new_frontend(request) if redirect_to_new_frontend?(request)
    RequestStore.store[:old_frontend] = old_frontend?(env)
    rewrite_path(env, request)
    @app.call(env)
  end

  private

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
end
