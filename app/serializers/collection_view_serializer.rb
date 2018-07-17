# frozen_string_literal: true

class CollectionViewSerializer < BaseSerializer
  attribute :count, predicate: NS::AS[:totalItems], unless: :system_scope?

  %i[first prev next last].each do |attr|
    attribute attr, predicate: NS::AS[attr], unless: :system_scope?
  end

  has_one :collection, predicate: NS::AS[:partOf]
  has_many :members, predicate: NS::AS[:items]
end
