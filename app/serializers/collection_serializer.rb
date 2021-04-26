# frozen_string_literal: true

class CollectionSerializer < LinkedRails::CollectionSerializer
  attribute :iri_template, predicate: NS::ONTOLA[:iriTemplate] do |object|
    object.iri_template.to_s.gsub(
      '{/parent_iri*}',
      object.parent&.iri&.to_s&.split('?')&.first || ActsAsTenant.current_tenant.iri
    )
  end
end
