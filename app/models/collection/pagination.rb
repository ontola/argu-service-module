# frozen_string_literal: true

class Collection
  module Pagination
    attr_accessor :before, :page

    def initialize(attrs = {})
      attrs[:type] = attrs[:type]&.to_sym
      unless %i[paginated infinite].include?(attrs[:type])
        raise ActionController::BadRequest.new("'#{attrs[:type]}' is not a valid collection type")
      end
      # rubocop:disable Rails/TimeZone
      attrs[:before] = Time.parse(attrs[:before]).to_s(:db) if attrs[:before].present?
      # rubocop:enable Rails/TimeZone
      super
    end

    def page_size
      @page_size&.to_i || association_class.default_per_page
    end

    def first
      case type
      when :paginated
        iri(iri_opts.merge(page: 1))
      when :infinite
        iri(iri_opts.merge(before: Time.current.utc.to_s(:db)))
      end
    end

    def last
      iri(iri_opts.merge(page: [total_page_count, 1].max)) if paginated? && total_page_count
    end

    def infinite?
      type == :infinite
    end

    def next
      case type
      when :paginated
        next_paginated
      when :infinite
        next_infinite
      end
    end

    def next_infinite
      return if before.nil? || members.blank?
      iri(iri_opts.merge(before: members.last.created_at.utc.to_s(:db)))
    end

    def next_paginated
      return if page.nil? || page.to_i >= (total_page_count || 0)
      iri(iri_opts.merge(page: page.to_i + 1))
    end

    def paginated?
      type == :paginated
    end

    def previous
      return if !paginated? || page.nil? || page.to_i <= 1
      iri(iri_opts.merge(page: page.to_i - 1))
    end

    private

    def parsed_sort_values
      {created_at: :desc}
    end

    def base_count
      @base_count ||= association_base.count
    end

    def include_before?
      infinite? && before.nil?
    end

    def members_infinite
      association_base
        .includes(association_class.includes_for_serializer)
        .where('created_at < ?', before)
        .order(parsed_sort_values)
        .limit(page_size)
    end

    def members_paginated
      association_base
        .includes(association_class.includes_for_serializer)
        .order(parsed_sort_values)
        .page(page)
        .per(page_size)
    end

    def total_page_count
      (base_count / page_size).ceil if base_count
    end
  end
end
