# frozen_string_literal: true

class Collection
  module Pagination
    attr_accessor :before, :page, :pagination

    def initialize(attrs = {})
      unless %i[paginated infinite].include?(attrs[:type])
        raise ActionController::BadRequest.new("'#{attrs[:type]}' is not a valid collection type")
      end
      attrs[:before] = DateTime.parse(attrs[:before]).utc.to_s(:db) if attrs[:before].present?
      super
    end

    def page_size
      association_class.default_per_page
    end

    def first
      case type
      when :paginated
        return unless pagination
        uri(query_opts.merge(page: 1))
      when :infinite
        uri(query_opts.merge(before: DateTime.current.utc.to_s(:db)))
      end
    end

    def last
      return unless paginated? && pagination
      uri(query_opts.merge(page: [total_page_count, 1].max))
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
      return if !pagination || before.nil?
      uri(query_opts.merge(before: members.last.created_at.utc.to_s(:db)))
    end

    def next_paginated
      return if !pagination || page.nil? || page.to_i >= total_page_count
      uri(query_opts.merge(page: page.to_i + 1))
    end

    def paginated?
      type == :paginated
    end

    def previous
      return if !pagination || page.nil? || page.to_i <= 1
      uri(query_opts.merge(page: page.to_i - 1))
    end

    private

    def include_before?
      infinite? && pagination && before.nil?
    end

    def include_pages?
      paginated? && pagination && page.nil?
    end

    def members_infinite
      policy_scope(association_base)
        .includes(includes)
        .where('created_at < ?', before)
        .order(order)
        .limit(association_class.default_per_page)
    end

    def members_paginated
      policy_scope(association_base)
        .includes(includes)
        .order(order)
        .page(page)
    end

    def total_page_count
      (association_base.count / page_size).ceil
    end
  end
end