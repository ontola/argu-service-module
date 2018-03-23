# frozen_string_literal: true

require 'argu/controller/error_handling/data_structures'
require 'argu/controller/error_handling/handlers'
require 'argu/controller/error_handling/helpers'

module Argu
  module Controller
    # The generic Argu error handling code. Currently a mess from different error
    # classes with inconsistent attributes.
    module ErrorHandling
      extend ActiveSupport::Concern

      include DataStructures
      include Handlers
      include Helpers

      included do
        rescue_from StandardError, with: :handle_and_report_error
        rescue_from Argu::Errors::Unauthorized, with: :handle_error
        rescue_from Argu::Errors::Forbidden, with: :handle_error
        rescue_from ActiveRecord::RecordNotFound, with: :handle_error
        rescue_from ActiveRecord::RecordNotUnique, with: :handle_error
        rescue_from ActiveRecord::StaleObjectError, with: :handle_error
        rescue_from ActionController::BadRequest, with: :handle_error
        rescue_from ActionController::ParameterMissing, with: :handle_error
        rescue_from ActionController::UnpermittedParameters, with: :handle_error
        rescue_from OAuth2::Error, with: :handle_oauth_error
      end
    end
  end
end
