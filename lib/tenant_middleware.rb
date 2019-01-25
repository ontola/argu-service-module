# frozen_string_literal: true

require_relative '../../lib/tenant_finder'
require_relative '../../app/helpers/jwt_helper'

class TenantMiddleware
  include JWTHelper

  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    ActsAsTenant.current_tenant = TenantFinder.from_request(request)
    Rails.logger.debug ActsAsTenant.current_tenant ? "Tenant: #{ActsAsTenant.current_tenant.url}" : 'No tenant found'
    RequestStore.store[:old_frontend] = old_frontend?(env)
    rewrite_path(env, request)
    @app.call(env)
  end

  private

  def old_frontend?(env)
    env['HTTP_AUTHORIZATION'].blank? || !decode_token(env['HTTP_AUTHORIZATION'][7..-1])['scopes'].include?('afe')
  end

  def rewrite_path(env, request)
    return if ActsAsTenant.current_tenant.nil? || ActsAsTenant.current_tenant.iri_prefix == request.host
    env['PATH_INFO'].gsub!(%r{(\/(#{ActsAsTenant.current_tenant.url}|#{ActsAsTenant.current_tenant.uuid}))(\/|$)}, '')
  end
end
