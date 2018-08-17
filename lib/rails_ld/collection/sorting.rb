# frozen_string_literal: true

module RailsLD
  class Collection
    module Sorting
      attr_accessor :sort
      attr_writer :default_sortings

      def default_sortings
        @default_sortings || [{key: NS::SCHEMA[:dateCreated], direction: :desc}]
      end

      def sorted?
        sort.present?
      end

      def sortings
        @sortings ||= (sort || default_sortings)&.map do |sort|
          RailsLD.collection_sorting.constantize.new(
            association_class: association_class,
            direction: sort[:direction],
            key: sort[:key]
          )
        end
      end
    end
  end
end
