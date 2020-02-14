# frozen_string_literal: true

require 'argu/errors/forbidden'

module Argu
  module Controller
    module Authentication
      extend ActiveSupport::Concern

      included do
        before_action :check_if_registered
      end

      def current_user
        @current_user ||= user_from_token || guest_user
      end

      def user_context
        @user_context ||= UserContext.new(api: api, user: current_user, doorkeeper_scopes: current_user.scopes)
      end

      private

      def authorization_header?
        request.headers['Authorization'].present?
      end

      def check_if_registered
        raise Argu::Errors::Unauthorized if current_user.guest?
      end

      def generate_guest_token
        @user_token = api.generate_guest_token(r: r_for_guest_token)
      end

      def guest_user
        token = generate_guest_token
        response.headers['New-Authorization'] = token
        CurrentUser.from_token(token)
      end

      def r_for_guest_token
        request.original_url
      end

      def token_from_header
        request.headers['Authorization'][7..-1] if request.headers['Authorization']&.downcase&.start_with?('bearer ')
      end

      def user_from_token
        user = CurrentUser.from_token(user_token)
        user if user&.id&.present?
      end

      def user_token
        @user_token ||= token_from_header
      end
    end
  end
end
