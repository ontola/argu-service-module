# frozen_string_literal: true

class CollectionFilterSerializer < BaseSerializer
  attribute :key, predicate: NS::ARGU[:filterKey]
  attribute :value, predicate: NS::ARGU[:filterValue]
end
