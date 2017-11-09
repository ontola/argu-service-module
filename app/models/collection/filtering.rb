# frozen_string_literal: true

class Collection
  module Filtering
    attr_accessor :filter

    private

    def filter?
      association_class.filter_options.present? && filter.blank? && association_class.filter_options.any? do |_k, v|
        v.present?
      end
    end

    def filter_views
      association_class.filter_options.map do |key, values|
        values[:values].map { |value| child_with_options(filter: {key => value[0]}) }
      end.flatten
    end

    def filter_query
      return if filter.blank?
      queries, values = filter_query_with_values
      [queries.join(' AND '), *values]
    end

    def filter_query_with_values
      queries = []
      values = []
      filter.map do |k, v|
        options = association_class.filter_options.fetch(k)
        value = filter_single_value(options, v)
        values << value unless value.is_a?(String) && value.include?('NULL')
        queries << filter_single_query(options, k, value)
      end
      [queries, values]
    end

    def filter_single_query(options, key, value)
      key = options[:key] || key
      if value.is_a?(String) && value.include?('NULL')
        [key, value].join(' IS ')
      else
        [key, '?'].join(' = ')
      end
    end

    def filter_single_value(options, value)
      options[:values].try(:[], value.try(:to_sym)) || value
    end
  end
end
