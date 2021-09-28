# frozen_string_literal: true

module Argu
  module Errors
    class Forbidden < StandardError
      attr_reader :query, :record, :policy, :action

      # @param [Hash] options
      # @option options [String] query The action of the request
      # @option options [ActiveRecord::Base] record The record that was requested
      # @option options [Policy] policy The policy that raised the exception
      # @return [String] the message
      def initialize(**options)
        @query  = options.fetch(:query).to_s
        @record = options[:record]
        @policy = options[:policy]
        @action = @query[-1] == '?' ? @query[0..-2] : @query
        @message = options[:message]

        raise StandardError if @query.blank? && @message.blank?

        super(@message || default_message)
      end

      private

      def default_message
        I18n.t(
          "pundit.#{@policy.class.to_s.underscore}.#{@query}",
          action: @action,
          default: I18n.t('errors.access_denied')
        )
      end
    end
  end
end
