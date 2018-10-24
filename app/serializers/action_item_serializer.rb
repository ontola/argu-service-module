# frozen_string_literal: true

class ActionItemSerializer < BaseSerializer
  attribute :label, predicate: NS::SCHEMA[:name]
  attribute :description, predicate: NS::SCHEMA[:text]
  attribute :result, predicate: NS::SCHEMA[:result]
  attribute :action_status, predicate: NS::SCHEMA[:actionStatus]
  attribute :favorite, predicate: NS::ARGU[:favoriteAction]

  has_one :resource, predicate: NS::SCHEMA[:object]
  has_one :target, predicate: NS::SCHEMA[:target]

  delegate :type, to: :object

  def result
    object.result&.iri
  end
end
