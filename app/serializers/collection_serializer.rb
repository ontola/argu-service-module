# frozen_string_literal: true

class CollectionSerializer < BaseSerializer
  attribute :title, predicate: NS::AS[:name]
  attribute :total_count, predicate: NS::AS[:totalItems], unless: :system_scope?
  attribute :iri_template, predicate: NS::ARGU[:iriTemplate]
  attribute :default_type, predicate: NS::ARGU[:defaultType]

  has_one :unfiltered_collection, predicate: NS::ARGU[:isFilteredCollectionOf], if: :filtered?
  has_one :part_of, predicate: NS::SCHEMA[:isPartOf]
  has_one :default_view, predicate: NS::AS[:pages]
  has_many :default_filtered_collections, predicate: NS::ARGU[:filteredCollections]

  has_many :actions, key: :operation, unless: :system_scope?, predicate: NS::SCHEMA[:potentialAction]
  has_many :filters, predicate: NS::ARGU[:collectionFilter]

  triples :action_methods

  def action_methods
    triples = []
    object.actions&.each { |action| triples.concat(action_triples(action)) }
    triples
  end

  def type
    return object.class.iri unless object.filtered?
    NS::ARGU[:FilteredCollection]
  end

  private

  def action_for_parent(action)
    action_triple(object.parent, NS::SCHEMA[:potentialAction], action.iri, NS::LL[:add]) if object.parent
  end

  def action_triples(action)
    [
      action_triple(object, NS::ARGU["#{action.tag}_action".camelize(:lower)], action.iri, NS::LL[:add]),
      action_for_parent(action)
    ].compact
  end

  def action_triple(subject, predicate, iri, graph = nil)
    [subject.iri, predicate, iri, graph]
  end

  delegate :filtered?, to: :object
end
