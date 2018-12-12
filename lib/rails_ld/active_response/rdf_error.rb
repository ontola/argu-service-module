# frozen_string_literal: true

module RailsLD
  module ActiveResponse
    class RDFError
      SCHEMA = ::RDF::Vocabulary.new('http://schema.org/')
      ONTOLA = ::RDF::Vocabulary.new('https://ns.ontola.io/')

      attr_accessor :error, :requested_url, :status

      def initialize(status, requested_url, original_error)
        self.status = status
        self.error = original_error.is_a?(StandardError) ? original_error : original_error.new
        self.requested_url = ::RDF::URI(requested_url)
      end

      def graph
        g = ::RDF::Graph.new
        g << [requested_url, SCHEMA[:name], title]
        g << [requested_url, SCHEMA[:text], error.message]
        g << [requested_url, ::RDF[:type], type]
        g
      end

      private

      def title
        @title ||= I18n.t('status')[status] || I18n.t('status')[500]
      end

      def type
        @type ||= ONTOLA["errors/#{error.class.name.demodulize}Error"]
      end
    end
  end
end
