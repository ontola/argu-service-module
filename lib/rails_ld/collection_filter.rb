# frozen_string_literal: true

module RailsLD
  class CollectionFilter < RDF::Node
    include ActiveModel::Serialization
    include ActiveModel::Model
    include Iriable

    attr_accessor :key, :value

    def iri(_opts = {})
      RDF::Node(id)
    end
  end
end
