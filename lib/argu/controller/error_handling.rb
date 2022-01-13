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
    end
  end
end
