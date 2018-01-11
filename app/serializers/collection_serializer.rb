# frozen_string_literal: true

class CollectionSerializer < BaseSerializer
  include Actionable::Serializer
  include_actions

  attribute :page_size, predicate: NS::ARGU[:pageSize]
  attribute :title, predicate: NS::SCHEMA[:name]
  attribute :total_count, predicate: NS::ARGU[:totalCount]
  attribute :parent_view_iri, predicate: NS::ARGU[:parentView]

  %i[first previous next last].each do |attr|
    attribute attr, predicate: NS::ARGU[attr]
  end

  has_one :parent, predicate: NS::SCHEMA[:isPartOf]

  has_many :members, predicate: NS::ARGU[:members]
  has_many :views, predicate: NS::ARGU[:views]

  def type
    return NS::ARGU[:InfiniteCollection] if object.infinite?
    super
  end

  def members
    object.association_class == Collection::EDGE_CLASS ? object.members&.map(&:owner) : object.members
  end
end
