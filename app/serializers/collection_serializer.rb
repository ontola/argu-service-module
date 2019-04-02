# frozen_string_literal: true

class CollectionSerializer < BaseSerializer
  attribute :title, predicate: NS::AS[:name]
  attribute :total_count, predicate: NS::AS[:totalItems], unless: :system_scope?
  attribute :iri_template, predicate: NS::ARGU[:iriTemplate]
  attribute :default_type, predicate: NS::ARGU[:defaultType]
  attribute :display, predicate: NS::ARGU[:collectionDisplay]
  attribute :columns, predicate: NS::ARGU[:columns]

  has_one :unfiltered_collection, predicate: NS::ARGU[:isFilteredCollectionOf], if: :filtered?
  has_one :part_of, predicate: NS::SCHEMA[:isPartOf]
  has_one :default_view, predicate: NS::AS[:pages]
  has_many :default_filtered_collections, predicate: NS::ARGU[:filteredCollections]

  has_many :actions, key: :operation, unless: :system_scope?, predicate: NS::SCHEMA[:potentialAction]
  has_many :filters, predicate: NS::ARGU[:collectionFilter]
  has_many :sortings, predicate: NS::ARGU[:collectionSorting]

  triples :action_methods

  def actions
    object.actions(scope).select(&:available?)
  end

  def action_methods
    actions&.map(&method(:action_triple))
  end

  def columns
    return unless object.display == 'settingsTable'

    columns_list = object.association_class.try(:defined_columns).try(:[], :settings)
    RDF::List[*columns_list] if columns_list.present?
  end

  def default_type
    object.type
  end

  def display
    NS::ARGU["collectionDisplay/#{object.display || :default}"]
  end

  def type
    return object.class.iri unless object.filtered?
    NS::ARGU[:FilteredCollection]
  end

  private

  def action_triple(action)
    predicate = NS::ARGU["#{action.tag}_action".camelize(:lower)]
    iri = action.iri
    subject_iri = object.iri
    subject_iri = RDF::DynamicURI(subject_iri.to_s.sub('/lr/', '/od/')) if object.class.to_s == 'LinkedRecord'
    [subject_iri, predicate, iri]
  end

  delegate :filtered?, to: :object
end
