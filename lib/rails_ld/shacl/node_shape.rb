# frozen_string_literal: true

module RailsLD
  module SHACL
    class NodeShape < Shape
      attr_accessor :closed,
                    :or,
                    :not,
                    :property

      def self.iri
        NS::SH[:NodeShape]
      end
    end
  end
end
