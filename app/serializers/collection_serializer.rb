# frozen_string_literal: true

class CollectionSerializer < BaseSerializer
  attribute :page_size, predicate: NS::ARGU[:pageSize]
  attribute :title, predicate: NS::SCHEMA[:name]
  attribute :total_count, predicate: NS::ARGU[:totalCount], unless: :system_scope?
  attribute :parent_view_iri, predicate: NS::ARGU[:parentView]

  %i[first previous next last].each do |attr|
    attribute attr, predicate: NS::ARGU[attr], unless: :system_scope?
  end

  has_one :part_of, predicate: NS::SCHEMA[:isPartOf]

  has_one :member_sequence, predicate: NS::ARGU[:members], if: :members?
  has_one :view_sequence, predicate: NS::ARGU[:views], if: :views?

  has_many :actions, key: :operation, unless: :system_scope?, predicate: NS::HYDRA[:operation]

  triples :action_methods

  def action_methods
    triples = []
    object.actions&.each { |action| triples.concat(action_triples(action)) }
    triples
  end

  def type
    return NS::ARGU[:InfiniteCollection] if object.infinite?
    super
  end

  def members?
    object.members.present?
  end

  def views?
    object.views.present?
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
