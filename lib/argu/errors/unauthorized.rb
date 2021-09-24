# frozen_string_literal: true

module Argu
  module Errors
    class Unauthorized < StandardError
      attr_accessor :redirect

      # @param [Hash] options
      # @option options [String] redirect_url The url to redirect to after sign in
      # @option options [String] message The message to show
      # @return [String] the message
      def initialize(**options)
        @redirect = options[:redirect_url]

        message = options[:message] || I18n.t('errors.unauthorized')
        super(message)
      end

      def redirect_url
        redirect_url!.to_s.presence
      end

      def redirect_url!
        @redirect
      end
    end
  end
end
