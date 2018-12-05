# frozen_string_literal: true

require_relative '../../lib/rails_ld'

RailsLD.collection_class = 'Collection'
RailsLD.collection_filter_class = 'CollectionFilter'
RailsLD.collection_sorting_class = 'CollectionSorting'
RailsLD.collection_view_class = 'CollectionView'
RailsLD.infinite_collection_view_class = 'InfiniteCollectionView'
RailsLD.paginated_collection_view_class = 'PaginatedCollectionView'
