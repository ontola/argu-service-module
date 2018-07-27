# frozen_string_literal: true

module RailsLD
  class PaginatedCollectionView < RailsLD.parent_collection_view.constantize
    attr_accessor :page

    def first
      iri(iri_opts.merge(page: 1))
    end

    def last
      iri(iri_opts.merge(page: [total_page_count, 1].max)) if total_page_count
    end

    def next
      return if page.nil? || page.to_i >= (total_page_count || 0)
      iri(iri_opts.merge(page: page.to_i + 1))
    end

    def prev
      return if page.nil? || page.to_i <= 1
      iri(iri_opts.merge(page: page.to_i - 1))
    end

    private

    def iri_opts
      {
        page: page,
        pageSize: page_size,
        type: :paginated
      }.merge(collection.iri_opts)
    end

    def raw_members
      association_base
        .includes(association_class.includes_for_serializer)
        .order(parsed_sort_values)
        .page(page)
        .per(page_size)
        .to_a
    end
  end
end
