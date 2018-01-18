# frozen_string_literal: true

module Argu
  module Errors
    class SerializableError
      attr_accessor :error, :requested_url, :status

      def initialize(status, requested_url, error)
        self.status = status
        self.error = error
        self.requested_url = RDF::URI(requested_url)
      end

      def read_attribute_for_serialization(attr)
        respond_to?(attr) ? send(attr) : error.send(attr)
      end

      def title
        I18n.t('status')[status] || I18n.t('status')[500]
      end
    end
  end
end
