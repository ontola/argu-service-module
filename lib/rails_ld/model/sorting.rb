# frozen_string_literal: true

module RailsLD
  module Model
    module Sorting
      extend ActiveSupport::Concern

      included do
        class_attribute :default_sortings, instance_accessor: false, instance_predicate: false
        self.default_sortings = [{key: NS::SCHEMA[:dateCreated], direction: :desc}]
      end
    end
  end
end
