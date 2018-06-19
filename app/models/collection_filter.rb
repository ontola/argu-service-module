# frozen_string_literal: true

class CollectionFilter < RDF::Node
  include ActiveModel::Serialization
  include ActiveModel::Model
  include Iriable

  attr_accessor :key, :value

  def iri(_opts = {})
    RDF::URI("_:#{id}")
  end
end
