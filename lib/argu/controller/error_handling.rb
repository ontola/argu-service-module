# frozen_string_literal: true

module Argu
  module Controller
    # The generic Argu error handling code. Currently a mess from different error
    # classes with inconsistent attributes.
    module ErrorHandling
      extend ActiveSupport::Concern

      include ErrorHandling::DataStructures
      include ErrorHandling::Handlers
      include ErrorHandling::Helpers

      included do
        rescue_from OAuth2::Error, with: :handle_oauth_error
      end

      module ClassMethods
        def error_status_codes # rubocop:disable Metrics/MethodLength
          @error_status_codes ||= {
            'ActionController::ParameterMissing' => 422,
            'ActionController::RoutingError' => 404,
            'ActionController::UnpermittedParameters' => 422,
            'ActiveRecord::RecordNotFound' => 404,
            'ActiveRecord::RecordNotUnique' => 304,
            'Doorkeeper::Errors::InvalidGrantReuse' => 422,
            'LinkedRails::Auth::Errors::Expired' => 410,
            'LinkedRails::Errors::Unauthorized' => 401,
            'Pundit::NotAuthorizedError' => 403,
            'LinkedRails::Errors::Forbidden' => 403,
            'Argu::Errors::Unauthorized' => 401,
            'Argu::Errors::WrongPassword' => 401,
            'Argu::Errors::UnknownEmail' => 401,
            'Argu::Errors::AccountLocked' => 401,
            'Argu::Errors::NoPassword' => 401
          }
        end
      end
    end
  end
end
