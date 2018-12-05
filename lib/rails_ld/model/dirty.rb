# frozen_string_literal: true

module RailsLD
  module Model
    module Dirty
      def previous_changes_by_predicate
        return {} unless respond_to?(:previous_changes)
        Hash[
          previous_changes
            .map { |k, v| [self.class.serializer_class!._attributes_data[k.to_sym]&.options.try(:[], :predicate), v] }
            .select { |k, _v| k.present? }
        ]
      end
    end
  end
end
