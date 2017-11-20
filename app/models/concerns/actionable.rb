# frozen_string_literal: true

module Actionable
  extend ActiveSupport::Concern

  included do
    def actions(user_context)
      @actions ||= "#{self.class}Actions"
                     .constantize
                     .new(resource: self, user_context: user_context)
                     .actions
    end

    def action(user_context, tag)
      actions(user_context).find { |a| a.tag == tag } || raise("Action '#{tag}' not available for #{self.class.name}")
    end
  end

  module Serializer
    extend ActiveSupport::Concern

    module ClassMethods
      def include_actions
        has_many :actions, key: :operation, predicate: NS::HYDRA[:operation] do
          object.actions(scope) if scope.is_a?(UserContext)
        end
        define_action_methods
      end

      def define_action_methods
        "#{name.gsub('Serializer', '')}Actions".constantize.defined_actions.each do |action|
          method_name = "#{action}_action"
          define_method method_name do
            object.action(scope, action) if scope.is_a?(UserContext)
          end

          has_one method_name,
                  predicate: NS::ARGU[method_name.camelize(:lower)]
        end
      end
    end
  end
end
