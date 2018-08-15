# frozen_string_literal: true

module RailsLD
  class CollectionFilter < RDF::Node
    include ActiveModel::Serialization
    include ActiveModel::Model

    attr_accessor :key, :value
  end
end
