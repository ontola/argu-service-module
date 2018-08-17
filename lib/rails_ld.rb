# frozen_string_literal: true

module RailsLD
  mattr_accessor :parent_collection_view
  mattr_accessor :infinite_collection_view
  mattr_accessor :paginated_collection_view
  mattr_accessor :collection_filter
  mattr_accessor :collection_sorting
  self.parent_collection_view = 'RailsLD::CollectionView'
  self.infinite_collection_view = 'RailsLD::InfiniteCollectionView'
  self.paginated_collection_view = 'RailsLD::PaginatedCollectionView'
  self.collection_filter = 'RailsLD::CollectionFilter'
  self.collection_sorting = 'RailsLD::CollectionSorting'
end
