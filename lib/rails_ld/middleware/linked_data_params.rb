# frozen_string_literal: true

module RailsLD
  module Middleware
    class LinkedDataParams
      def self.classes_by_iri
        @classes_by_iri ||=
          Hash[
            ActiveRecord::Base
              .descendants
              .select { |klass| klass.respond_to?(:iri) }
              .map { |klass| [klass.iri.to_s, klass] }
          ].freeze
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        request = Rack::Request.new(env)
        params_from_graph(request)
        @app.call(env)
      end

      private

      def graph_from_request(request)
        request_graph = request.delete_param("<#{NS::LL[:graph].value}>")
        RDF::Graph.load(request_graph[:tempfile].path, content_type: request_graph[:type]) if request_graph.present?
      end

      def logger
        Rails.logger
      end

      # Converts a serialized graph from a multipart request body to a nested
      # attributes hash.
      #
      # The graph sent to the server should be sent under the `ll:graph` form name.
      # The entrypoint for the graph is the `ll:targetResource` subject, which is
      # assumed to be the resource intended to be targeted by the request (i.e. the
      # resource to be created, updated, or deleted).
      #
      # @return [Hash] A hash of attributes, empty if no statements were given.
      def params_from_graph(request)
        graph = graph_from_request(request)
        target_class = graph && target_class_from_path(request.path, request.request_method)
        if target_class.blank?
          logger.info("No class found for #{request.path}") if graph
          return
        end

        request.update_param(
          target_class.to_s.underscore,
          parse_resource(graph, NS::LL[:targetResource], target_class, request.params)
        )
      end

      def parse_nested_resource(graph, subject, klass, base_params)
        resource = parse_resource(graph, subject, klass, base_params)
        resource[:id] ||= nil
        resource
      end

      # Recursively parses a resource from graph
      def parse_resource(graph, subject, klass, base_params)
        HashWithIndifferentAccess[
          graph
            .query([subject])
            .map { |statement| parse_statement(graph, statement, klass, base_params) }
            .compact
        ]
      end

      def parse_statement(graph, statement, klass, base_params)
        field = serializer_field(klass, statement.predicate)
        if field.is_a?(ActiveModel::Serializer::Attribute)
          parsed_attribute(field.name, statement.object.value, base_params)
        elsif field.is_a?(ActiveModel::Serializer::Reflection)
          parsed_association(graph, statement.object, klass, field.options[:association] || field.name, base_params)
        end
      end

      def parsed_association(graph, object, klass, association, base_params)
        association_klass = klass.reflect_on_association(association).klass
        nested_resources =
          if graph.query([object, NS::RDFV[:first], nil]).present?
            RDF::List.new(subject: object, graph: graph)
              .map { |nested| parse_nested_resource(graph, nested, association_klass, base_params) }
          else
            parse_nested_resource(graph, object, association_klass, base_params)
          end
        ["#{association}_attributes", nested_resources]
      end

      def parsed_attribute(key, value, base_params)
        [key, value.starts_with?(NS::LL['blobs/']) ? base_params["<#{value}>"] : value]
      end

      def serializer_field(klass, predicate)
        field = klass.try(:predicate_mapping).try(:[], predicate)
        logger.info("#{predicate} not found for #{klass}") if field.blank?
        field
      end

      def target_class_from_path(path, method)
        opts = Rails.application.routes.recognize_path(path, method: method)
        class_name = opts[:controller]&.classify
        class_name&.safe_constantize ||
          class_name&.deconstantize&.classify&.safe_constantize
      rescue ActionController::RoutingError
        nil
      end
    end
  end
end
