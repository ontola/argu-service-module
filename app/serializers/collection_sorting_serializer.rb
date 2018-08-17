# frozen_string_literal: true

class CollectionSortingSerializer < BaseSerializer
  attribute :key, predicate: NS::ARGU[:sortKey]
  attribute :direction, predicate: NS::ARGU[:sortDirection]
end
