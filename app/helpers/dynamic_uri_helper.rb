# frozen_string_literal: true

module DynamicUriHelper
  module_function

  def old_frontend_prefix(tenant)
    "#{Rails.application.config.host_name}/#{tenant.url}"
  end

  def tenant_prefix(tenant)
    RequestStore.store[:old_frontend] ? DynamicUriHelper.old_frontend_prefix(tenant) : tenant.iri_prefix
  end

  def revert(uri, tenant)
    return uri if tenant.nil?

    uri.to_s.sub("://#{tenant_prefix(tenant)}", "://#{Rails.application.config.host_name}")
  end

  def rewrite(uri, tenant = ActsAsTenant.current_tenant)
    return uri if tenant.nil?

    uri.to_s.sub("://#{Rails.application.config.host_name}", "://#{tenant_prefix(tenant)}")
  end
end
