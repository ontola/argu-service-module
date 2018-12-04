# frozen_string_literal: true

module RailsLD
  module SHACL
    class NodeShapeSerializer < ShapeSerializer
      include RailsLD::Serializer

      attribute :closed, predicate: NS::SH[:closed]
      attribute :or, predicate: NS::SH[:or]
      attribute :not, predicate: NS::SH[:not]

      has_many :property, predicate: NS::SH[:property]

      def type
        NS::SH[:NodeShape]
      end
    end
  end
end
