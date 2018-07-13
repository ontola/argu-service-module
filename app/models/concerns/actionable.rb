# frozen_string_literal: true

module Actionable
  extend ActiveSupport::Concern

  included do
    def actions(user_context)
      @actions ||= self.class.actions_class!.new(resource: self, user_context: user_context).actions
    end

    def action(user_context, tag)
      actions(user_context).find { |a| a.tag.to_sym == tag.to_sym }
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
        has_many :actions,
                 key: :operation,
                 unless: :system_scope?,
                 predicate: NS::SCHEMA[:potentialAction] do
          object.actions(scope) if scope.is_a?(UserContext)
        end
        define_action_methods
      end

      def define_action_methods
        actions_class.defined_actions&.each do |tag, _opts|
          method_name = "#{tag}_action"
          define_method method_name do
            object.action(scope, tag) if scope.is_a?(UserContext)
          end

          has_one method_name,
                  predicate: NS::ARGU[method_name.camelize(:lower)],
                  unless: :system_scope?
        end
      end

      def actions_class
        name.gsub('Serializer', '').constantize.actions_class!
      end
      # rubocop:enable Rails/HasManyOrHasOneDependent
    end
  end
end
