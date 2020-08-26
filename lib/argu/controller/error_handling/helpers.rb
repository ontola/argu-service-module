# frozen_string_literal: true

module Argu
  module Controller
    # The generic Argu error handling code. Currently a mess from different error
    # classes with inconsistent attributes.
    module ErrorHandling
      module Helpers
        def error_id(error)
          Argu::Errors::ERROR_TYPES[error.class.to_s].try(:[], :id) || 'SERVER_ERROR'
        end

        def error_mode(exception)
          @_error_mode = true
          Rails.logger.error exception
          @_uc = nil
        end

        def error_status(error)
          Argu::Errors::ERROR_TYPES[error.class.to_s].try(:[], :status) || 500
        end

        def user_with_r(redirect)
          User.new(redirect_url: redirect, shortname: Shortname.new)
        end
      end
    end
  end
end
