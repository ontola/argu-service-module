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

        def error_status(error)
          Argu::Errors::ERROR_TYPES[error.class.to_s].try(:[], :status) || 500
        end
      end
    end
  end
end
