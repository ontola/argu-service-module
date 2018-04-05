# frozen_string_literal: true

class ActionItemSerializer < BaseSerializer
  attribute :label, predicate: NS::SCHEMA[:name]
  attribute :result, predicate: NS::SCHEMA[:result]

  has_one :resource, predicate: NS::SCHEMA[:object]
  has_one :target, predicate: NS::SCHEMA[:target]

  delegate :type, to: :object

  def result
    object.result&.iri
  end
end
