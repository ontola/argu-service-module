# frozen_string_literal: true

module ActsAsTenant
  def self.current_tenant=(tenant)
    if tenant&.database_schema && tenant.database_schema != Apartment::Tenant.current
      Tenant.create(tenant.database_schema) unless ApplicationRecord.connection.schema_exists?(tenant.database_schema)

      Apartment::Tenant.switch!(tenant.database_schema)
    end
    RequestStore.store[:current_tenant] = tenant
  end
end
