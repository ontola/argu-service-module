# frozen_string_literal: true

class CollectionSerializer < BaseSerializer
  attribute :items_per_page, predicate: NS::ARGU[:pageSize]
  attribute :title, predicate: NS::SCHEMA[:name]
  attribute :total_count, predicate: NS::ARGU[:totalCount]
  attribute :parent_view_iri, predicate: NS::ARGU[:parentView]

  %i[first previous next last].each do |attr|
    attribute attr, predicate: NS::ARGU[attr]
  end

  has_one :parent, predicate: NS::SCHEMA[:isPartOf]
  has_one :create_action, predicate: NS::ARGU[:createAction]

  has_many :members, predicate: NS::ARGU[:members]
  has_many :views, predicate: NS::ARGU[:views]
end
