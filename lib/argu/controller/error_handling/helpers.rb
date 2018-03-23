# frozen_string_literal: true

module Argu
  module Controller
    # The generic Argu error handling code. Currently a mess from different error
    # classes with inconsistent attributes.
    module ErrorHandling
      module Helpers
        def error_id(e)
          Argu::Errors::TYPES[e.class.to_s].try(:[], :id) || 'SERVER_ERROR'
        end

        def error_mode(exception)
          @_error_mode = true
          Rails.logger.error exception
          @_uc = nil
        end

        def error_status(e)
          Argu::Errors::TYPES[e.class.to_s].try(:[], :status) || 500
        end

        def user_with_r(r)
          User.new(r: r, shortname: Shortname.new)
        end
      end
    end
  end
end
