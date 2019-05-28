# frozen_string_literal: true

class CollectionFilterSerializer < BaseSerializer
  attribute :key, predicate: NS::ONTOLA[:filterKey]
  attribute :value, predicate: NS::ONTOLA[:filterValue]
end
