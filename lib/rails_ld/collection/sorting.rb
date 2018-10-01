# frozen_string_literal: true

module RailsLD
  class Collection
    module Sorting
      attr_accessor :sort
      attr_writer :default_sortings

      def default_sortings
        opts = @default_sortings || association_class.default_sortings
        opts.respond_to?(:call) ? opts.call(parent) : opts
      end

      def sorted?
        sort.present?
      end

      def sortings
        @sortings ||=
          RailsLD.collection_sorting.constantize.from_array(association_class, sort || default_sortings)
      end
    end
  end
end
