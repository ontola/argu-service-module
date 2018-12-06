# frozen_string_literal: true

require_relative 'model/collections'
require_relative 'model/dirty'
require_relative 'model/filtering'
require_relative 'model/iri'
require_relative 'model/sorting'

module RailsLD
  module Model
    extend ActiveSupport::Concern

    include Collections
    include Dirty
    include Filtering
    include Iri
    include Sorting

    def build_child(klass)
      klass.new
    end

    module ClassMethods
      def includes_for_serializer
        {}
      end

      def predicate_mapping
        @predicate_mapping ||= Hash[attribute_mapping + reflection_mapping]
      end

      private

      def attribute_mapping
        ActiveModel::Serializer.serializer_for(self)
          ._attributes_data
          .values
          .select { |value| value.options[:predicate].present? }
          .map { |value| [value.options[:predicate], value] }
      end

      def reflection_mapping
        ActiveModel::Serializer.serializer_for(self)
          ._reflections
          .values
          .select { |value| value.options[:predicate].present? }
          .map { |value| [value.options[:predicate], value] }
      end
    end
  end
end
