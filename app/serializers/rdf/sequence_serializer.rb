# frozen_string_literal: true

module RDF
  class SequenceSerializer < BaseSerializer
    triples :sequence
    has_many :members

    def type
      RDF[:Seq]
    end

    def sequence
      object&.members&.map&.with_index { |item, index| [rdf_subject, RDF["_#{index}"], item.iri] } || []
    end

    def rdf_subject
      object.node
    end
  end
end
