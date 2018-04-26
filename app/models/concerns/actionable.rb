# frozen_string_literal: true

module Actionable
  extend ActiveSupport::Concern

  included do
    def actions(user_context)
      @actions ||= actions_class
                     .new(resource: self, user_context: user_context)
                     .actions
    end

    def action(user_context, tag)
      actions(user_context).find { |a| a.tag == tag }
    end
  end

  module Actions
    extend ActiveSupport::Concern

    included do
      class_attribute :defined_actions
      self.defined_actions ||= []

      def actions
        defined_actions.map { |action| send("#{action}_action") }.compact
      end

      def action
        Hash[defined_actions.map { |action| [action, send("#{action}_action")] }]
      end
    end

    module ClassMethods
      def define_action(action)
        self.defined_actions ||= []
        self.defined_actions += [action]
      end

      def define_actions(actions)
        actions.each { |a| define_action(a) }
      end
    end
  end

  module Serializer
    extend ActiveSupport::Concern

    included do
      include_actions
    end

    module ClassMethods
      # rubocop:disable Rails/HasManyOrHasOneDependent
      def include_actions
        has_many :actions, key: :operation, predicate: NS::HYDRA[:operation] do
          object.actions(scope) if scope.is_a?(UserContext)
        end
        define_action_methods
      end

      def define_action_methods
        actions_class.defined_actions.each do |action|
          method_name = "#{action}_action"
          define_method method_name do
            object.action(scope, action) if scope.is_a?(UserContext)
          end

          has_one method_name,
                  predicate: NS::ARGU[method_name.camelize(:lower)]
        end
      end

      def actions_class
        name.gsub('Serializer', '').constantize.actions_class!
      end
      # rubocop:enable Rails/HasManyOrHasOneDependent
    end
  end
end
