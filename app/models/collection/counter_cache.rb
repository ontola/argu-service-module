# frozen_string_literal: true

require_relative '../../../lib/rails_ld.rb'
require_relative '../../../lib/rails_ld/collection.rb'

class Collection < RailsLD::Collection
  module CounterCache
    def total_count
      @total_count ||= count_from_cache_column || super
    end

    private

    def count_from_cache_column
      return count_from_counter_culture if counter_culture_column
      parent.children_count(counter_cache_column) if counter_cache_column
    end

    def count_from_counter_culture
      parent.send(counter_culture_column)
    end

    def counter_cache_column
      return counter_cache_for_filter if filter&.count == 1
      return if filtered?
      @counter_cache_column ||= counter_cache_column_name
    end

    def counter_cache_column_name
      key = association.to_s
      key = key[7..-1] if key.starts_with?('active_')
      opts = association_class.try(:counter_cache_options)
      key if opts && (opts == true || opts.keys.include?(key.to_sym))
    end

    def counter_cache_for_filter
      association_class.filter_options[filter.keys.first].try(:[], :counter_cache).try(:[], filter.values.first)
    end

    def counter_culture_column
      column = "#{association}_count"
      column if !parent.try(:previous_changes)&.key?(:id) && parent.try(:attributes)&.keys&.include?(column)
    end
  end
end
