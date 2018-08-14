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

      def association_by_predicate(klass, predicate)
        association = model_reflections_map(klass).find { |opt| opt.options[:predicate] == predicate }
        association.options[:association] || association.name
      end

      def attribute_by_predicate(klass, predicate)
        model_attribute_map(klass).find { |opt| opt.options[:predicate] == predicate }
      end

      def graph_from_request(request)
        request_graph = request.delete_param("<#{NS::LL[:graph].value}>")
        RDF::Graph.load(request_graph[:tempfile].path, content_type: request_graph[:type]) if request_graph.present?
      end

      def logger
        Rails.logger
      end

      # Retrieves the attribute-predicate mapping from the serializer.
      #
      # Used to convert incoming predicates back to their respective attributes.
      def model_attribute_map(klass)
        @model_attribute_map ||= {}
        @model_attribute_map[klass] ||=
          model_serializer(klass)
            ._attributes_data
            .values
      end

      # Retrieves the reflections-predicate mapping from the serializer.
      #
      # Used to convert incoming predicates back to their respective reflections.
      def model_reflections_map(klass)
        @model_reflections_map ||= {}
        @model_reflections_map[klass] ||=
          model_serializer(klass)
            ._reflections
            .values
      end

      def model_serializer(klass)
        @model_serializer ||= {}
        @model_serializer[klass] ||=
          "#{klass.name.underscore}_serializer"
            .classify
            .constantize
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
        target_class = graph && target_class_from_path(request.path)
        if target_class.blank?
          logger.info("No class found for #{request.path}") if graph
          return
        end

        request.update_param(
          target_class.to_s.underscore,
          parse_resource(graph, NS::LL[:targetResource], target_class, request.params)
        )
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

      def parsed_association(graph, object, klass, association, base_params)
        association_klass = klass.reflect_on_association(association).klass
        nested_resources =
          if graph.query([object, NS::RDFV[:first], nil]).present?
            RDF::List.new(subject: object, graph: graph)
              .map { |nested| parse_resource(graph, nested, association_klass, base_params) }
          else
            parse_resource(graph, object, association_klass, base_params)
          end
        ["#{association}_attributes", nested_resources]
      end

      def parsed_attribute(key, value, base_params)
        [key, value.starts_with?(NS::LL['blobs/']) ? base_params["<#{value}>"] : value]
      end

      def parse_statement(graph, statement, klass, base_params)
        attribute = attribute_by_predicate(klass, statement.predicate)
        return parsed_attribute(attribute.name, statement.object.value, base_params) if attribute

        association = association_by_predicate(klass, statement.predicate)
        return parsed_association(graph, statement.object, klass, association, base_params) if association

        logger.info("#{statement.predicate} not found in #{model_serializer(klass)}")
      end

      def target_class_from_path(path)
        opts = Rails.application.routes.recognize_path(path)
        opts[:controller]&.classify&.safe_constantize
      rescue ActionController::RoutingError
        nil
      end
    end
  end
end
