# frozen_string_literal: true

module RailsLD
  class FormOptionSerializer < ActiveModel::Serializer
    include RailsLD::Serializer

    attribute :label, predicate: NS::SCHEMA[:name]
    delegate :type, to: :object
  end
end
