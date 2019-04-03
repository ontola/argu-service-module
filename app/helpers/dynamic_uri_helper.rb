# frozen_string_literal: true

module DynamicUriHelper
  module_function

  def old_frontend_prefix(tenant)
    "#{Rails.application.config.host_name}/#{tenant.url}"
  end

  def tenant_prefix(tenant, old_frontend)
    old_frontend ? DynamicUriHelper.old_frontend_prefix(tenant) : tenant.iri_prefix
  end

  def revert(uri, tenant, old_frontend: RequestStore.store[:old_frontend])
    return uri if tenant.nil?

    uri.to_s.sub("://#{tenant_prefix(tenant, old_frontend)}", "://#{Rails.application.config.host_name}")
  end

  def rewrite(uri, tenant = ActsAsTenant.current_tenant, old_frontend: RequestStore.store[:old_frontend])
    return uri if tenant.nil?

    uri.to_s.sub("://#{Rails.application.config.host_name}", "://#{tenant_prefix(tenant, old_frontend)}")
  end
end
