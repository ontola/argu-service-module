# frozen_string_literal: true

module DynamicURIHelper
  module_function

  def tenant_prefix(tenant)
    tenant.iri_prefix.presence ||
      raise("No iri_prefix (#{tenant.iri_prefix.class}) for #{tenant.iri}\n#{tenant.inspect}\n#{tenant.tenant.inspect}")
  end

  def rewrite(url, tenant = ActsAsTenant.current_tenant)
    return url if tenant.nil? || url.to_s.include?("#{Rails.application.config.host_name}/i/")

    rewritten = url.to_s.chomp('/').sub("://#{Rails.application.config.host_name}", "://#{tenant_prefix(tenant)}")
    LinkedRails::URL.as_href(rewritten)
  end
end
