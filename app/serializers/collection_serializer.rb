# frozen_string_literal: true

class CollectionSerializer < LinkedRails::CollectionSerializer
  def iri_template
    object.iri_template.to_s.gsub('{/parent_iri*}', object.parent&.iri || ActsAsTenant.current_tenant.iri)
  end
end
