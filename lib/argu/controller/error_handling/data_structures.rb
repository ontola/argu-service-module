# frozen_string_literal: true

module Argu
  module Controller
    # The generic Argu error handling code. Currently a mess from different error
    # classes with inconsistent attributes.
    module ErrorHandling
      module DataStructures
        def json_error_hash(error)
          {code: error_id(error), message: error.message}
        end

        # @param [Integer] status HTTP response code
        # @param [Array<Hash, String>] errors A list of errors
        # @return [Hash] Error hash to use in a render method
        def json_error(status, errors = nil)
          errors = json_api_formatted_errors(errors, Rack::Utils::HTTP_STATUS_CODES[status])
          {
            json: {
              code: errors&.first.try(:[], :code),
              message: errors&.first.try(:[], :message),
              notifications: errors.map { |error| {type: :error, message: error[:message]} }
            },
            status: status
          }
        end
      end
    end
  end
end
