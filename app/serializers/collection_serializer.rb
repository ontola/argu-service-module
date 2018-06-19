# frozen_string_literal: true

class CollectionSerializer < BaseSerializer
  attribute :title, predicate: NS::SCHEMA[:name]
  attribute :total_count, predicate: NS::ARGU[:totalCount], unless: :system_scope?
  attribute :iri_template, predicate: NS::ARGU[:iriTemplate]

  has_one :unfiltered_collection, predicate: NS::ARGU[:isFilteredCollectionOf]
  has_one :part_of, predicate: NS::SCHEMA[:isPartOf]
  has_one :default_view, predicate: NS::ARGU[:views]
  has_many :default_filtered_collections, predicate: NS::ARGU[:filteredCollections]

  has_many :actions, key: :operation, unless: :system_scope?, predicate: NS::HYDRA[:operation]

  triples :action_methods

  def action_methods
    triples = []
    object.actions&.each { |action| triples.concat(action_triples(action)) }
    triples
  end

  def type
    return object.class.iri unless object.filtered?
    NS::ARGU[:filteredCollection]
  end

  private

  def action_triples(action)
    iri = action.iri
    [
      action_triple(object, NS::ARGU["#{action.tag}_action".camelize(:lower)], iri),
      object.parent ? action_triple(object.parent, NS::HYDRA[:operation], iri, NS::LL[:add]) : nil
    ].compact
  end

  def action_triple(subject, predicate, iri, graph = nil)
    [subject.iri, predicate, iri, graph]
  end
end
