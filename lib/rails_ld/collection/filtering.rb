# frozen_string_literal: true

module RailsLD
  class Collection
    module Filtering
      attr_accessor :filter

      def filtered?
        filter.present?
      end

      def filters
        @filters ||= filter&.map do |key, value|
          CollectionFilter.new(
            key: key,
            value: value
          )
        end
      end

      private

      def apply_filters(scope)
        (filter || []).reduce(scope) do |s, f|
          k = f[0]
          v = f[1]
          options = association_class.filter_options.fetch(k)
          apply_filter(s, options[:key] || k, filter_single_value(options, v))
        end
      end

      def apply_filter(scope, key, value)
        case value
        when 'NULL'
          scope.where(key => nil)
        when 'NOT NULL'
          scope.where.not(key => nil)
        else
          scope.where(key => value)
        end
      end

      def filter_single_value(options, value)
        options[:values].try(:[], value.try(:to_sym)) || value
      end
    end
  end
end
