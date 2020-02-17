# frozen_string_literal: true

module DynamicUriHelper
  module_function

  def tenant_prefix(tenant)
    tenant.iri_prefix.presence ||
      raise("No iri_prefix (#{tenant.iri_prefix.class}) for #{tenant.iri}\n#{tenant.inspect}\n#{tenant.tenant.inspect}")
  end

  def rewrite(uri, tenant = ActsAsTenant.current_tenant)
    return uri if tenant.nil? || uri.to_s.include?("#{Rails.application.config.host_name}/i/")

    uri.to_s.sub("://#{Rails.application.config.host_name}", "://#{tenant_prefix(tenant)}")
  end
end
