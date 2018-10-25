# frozen_string_literal: true

module RailsLD
  module ActiveResponse
    module Controller
      module Collections
        ACTION_FORM_INCLUDES = [
          target: {
            action_body: [
              referred_shapes: :property,
              property: [referred_shapes: :property, property: [referred_shapes: :property].freeze].freeze
            ].freeze
          }.freeze
        ].freeze

        private

        def action_form_includes(action = nil)
          ACTION_FORM_INCLUDES + [resource: form_resource_includes(action)]
        end

        def collection_includes(member_includes = {})
          {
            default_view: collection_view_includes(member_includes),
            filters: [],
            sortings: [],
            operation: action_form_includes
          }
        end

        def collection_view_includes(member_includes = {})
          {member_sequence: {members: member_includes}}
        end

        def collection_view_params
          params.permit(:before, :page)
        end

        def collection_type_params
          params.permit(:page_size, :type)
        end

        def form_resource_includes(action)
          includes = create_includes.presence || []
          return includes if action.blank?

          includes = [includes] if includes.is_a?(Hash)
          includes << %i[filters sortings] if action.resource.is_a?(Collection)
          includes << action.form&.referred_resources
          includes
        end

        def index_collection
          return if index_collection_name.blank?
          @index_collection ||=
            parent_resource!.send(
              index_collection_name,
              collection_options
            )
        end

        def index_collection_name
          return unless respond_to?(:parent_resource, true)
          return unless parent_resource.respond_to?("#{controller_name.singularize}_collection", true)
          "#{controller_name.singularize}_collection"
        end

        def index_collection_or_view
          collection_view_params.present? ? index_collection&.view_with_opts(collection_view_params) : index_collection
        end

        def index_includes_collection
          if collection_view_params.present?
            collection_view_includes(preview_includes)
          else
            collection_includes(preview_includes)
          end
        end

        def index_meta
          return [] if index_collection.is_a?(Collection)

          RDF::List.new(
            graph: RDF::Graph.new,
            subject: index_iri,
            values: index_collection.map(&:iri)
          ).triples
        end

        def index_iri
          RDF::DynamicURI(request.original_url)
        end

        def preview_includes
          []
        end

        def show_includes
          preview_includes
        end
      end
    end
  end
end
