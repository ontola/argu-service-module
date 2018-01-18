# frozen_string_literal: true

module Argu
  module Errors
    class SerializableError
      attr_accessor :error, :requested_url

      def initialize(requested_url, error)
        self.error = error
        self.requested_url = RDF::URI(requested_url)
      end

      def read_attribute_for_serialization(attr)
        error.send(attr)
      end
    end
  end
end
