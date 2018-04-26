# frozen_string_literal: true

class CollectionSerializer < BaseSerializer
  attribute :page_size, predicate: NS::ARGU[:pageSize]
  attribute :title, predicate: NS::SCHEMA[:name]
  attribute :total_count, predicate: NS::ARGU[:totalCount]
  attribute :parent_view_iri, predicate: NS::ARGU[:parentView]

  %i[first previous next last].each do |attr|
    attribute attr, predicate: NS::ARGU[attr]
  end

  has_one :part_of, predicate: NS::SCHEMA[:isPartOf]

  has_one :member_sequence, predicate: NS::ARGU[:members], if: :members?
  has_one :view_sequence, predicate: NS::ARGU[:views], if: :views?

  def type
    return NS::ARGU[:InfiniteCollection] if object.infinite?
    super
  end

  def members
    object.association_class == Collection::EDGE_CLASS ? object.members&.map(&:owner) : object.members
  end

  def members?
    object.members.present?
  end

  def views?
    object.views.present?
  end
end
