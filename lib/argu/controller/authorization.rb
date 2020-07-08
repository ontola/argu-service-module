# frozen_string_literal: true

module Argu
  module Controller
    module Authorization
      extend ActiveSupport::Concern
      include Pundit

      included do
        class_attribute :policy_scope_verification
        before_action :authorize_action
        after_action :verify_authorized, if: :verify_authorized?
        after_action :verify_policy_scoped, if: :verify_policy_scoped?

        alias_attribute :pundit_user, :user_context
      end

      private

      def authorize(record, query = nil, *opts)
        query ||= params[:action].to_s + '?'

        @_pundit_policy_authorized = true

        policy = policy(record)

        unless policy.public_send(query, *opts)
          raise Argu::Errors::Forbidden.new(query: query, record: record, policy: policy, message: policy.try(:message))
        end

        true
      end

      def authorize_action
        authorize current_resource || new_resource, "#{params[:action].chomp('!')}?"
      end

      def skip_verify_policy_authorized(sure = false)
        @_pundit_policy_authorized = true if sure
      end

      def skip_verify_policy_scoped(sure = false)
        @_pundit_policy_scoped = true if sure
      end

      def verify_authorized?
        action_name != 'index'
      end

      def verify_policy_scoped?
        action_name == 'index'
      end

      module ClassMethods
        private

        def authorize(user, record, query)
          policy = policy!(user, record)

          unless policy.public_send(query)
            raise Argu::Errors::Forbidden.new(
              query: query,
              record: record,
              policy: policy,
              message: policy.try(:message)
            )
          end

          true
        end
      end
    end
  end
end
