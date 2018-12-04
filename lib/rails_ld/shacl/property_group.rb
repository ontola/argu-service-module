# frozen_string_literal: true

module RailsLD
  module SHACL
    class PropertyGroup
      include ActiveModel::Serialization
      include ActiveModel::Model

      # Custom attributes
      attr_accessor :iri

      # SHACL attributes
      attr_accessor :label,
                    :order

      def initialize(attrs = {})
        super(attrs)
        @iri ||= RDF::Node.new
      end

      def self.iri
        NS::SH[:PropertyGroup]
      end
    end
  end
end
