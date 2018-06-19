# frozen_string_literal: true

class CollectionViewSerializer < BaseSerializer
  attribute :count, predicate: NS::ARGU[:totalCount], unless: :system_scope?

  %i[first previous next last].each do |attr|
    attribute attr, predicate: NS::ARGU[attr], unless: :system_scope?
  end

  has_one :collection, predicate: NS::ARGU[:isViewOf]
  has_many :members, predicate: NS::ARGU[:members]
end
