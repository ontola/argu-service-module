# frozen_string_literal: true

module RailsLD
  module SHACL
    class PropertyGroupSerializer < ActiveModel::Serializer
      include RailsLD::Serializer

      attribute :description, predicate: NS::SH[:description]
      attribute :label, predicate: NS::RDFS[:label]
      attribute :order, predicate: NS::SH[:order]

      def type
        NS::SH[:PropertyGroup]
      end
    end
  end
end
