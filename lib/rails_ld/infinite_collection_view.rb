# frozen_string_literal: true

module RailsLD
  class InfiniteCollectionView < RailsLD.parent_collection_view.constantize
    attr_accessor :before

    def initialize(attrs = {})
      # rubocop:disable Rails/TimeZone
      attrs[:before] = Time.parse(attrs[:before]).to_s(:db) if attrs[:before]
      # rubocop:enable Rails/TimeZone
      super
    end

    def first
      iri(iri_opts.merge(before: Time.current.utc.to_s(:db)))
    end

    def last; end

    def next
      return if before.nil? || members.blank?
      iri(iri_opts.merge(before: members.last.created_at.utc.to_s(:db)))
    end

    def prev; end

    def type
      :infinite
    end

    private

    def iri_opts
      {
        before: before,
        pageSize: page_size,
        type: :infinite
      }.merge(collection.iri_opts)
    end

    def raw_members
      @raw_members ||=
        association_base
          .includes(association_class.includes_for_serializer)
          .where(arel_table[:created_at].lt(before))
          .reorder(parsed_sort_values)
          .limit(page_size)
          .to_a
    end
  end
end
