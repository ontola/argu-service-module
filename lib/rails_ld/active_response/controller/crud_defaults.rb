# frozen_string_literal: true

require_relative 'collections'

module RailsLD
  module ActiveResponse
    module Controller
      module CrudDefaults
        include RailsLD::ActiveResponse::Controller::Collections
        ACTION_MAP = {
          edit: :update,
          bin: :trash,
          unbin: :untrash,
          delete: :destroy,
          new: :create,
          shift: :move
        }.freeze

        def active_response_action(resource:, view:)
          action_resource = resource.try(:new_record?) && index_collection || resource
          action_resource.action(user_context, active_response_action_name(view))
        end

        def active_response_action_name(view)
          form = params[:form]
          form ||= view == 'form' ? action_name : view
          ACTION_MAP[form.to_sym] || form.to_sym
        end

        def create_success_options_rdf
          opts = create_success_options
          opts[:meta] = create_meta
          opts
        end

        def create_meta
          []
        end

        def default_form_options(action)
          return super unless active_responder.is_a?(RDFResponder)
          action = active_response_action(super.slice(:resource, :view))
          {
            action: action || raise("No action found for #{action_name}"),
            include: action_form_includes(action)
          }
        end

        def destroy_success_options_rdf
          opts = destroy_success_options
          opts[:meta] = destroy_meta
          opts
        end

        def destroy_meta
          []
        end

        def index_success_options_rdf
          return index_success_options if index_collection_or_view.nil?
          {
            collection: index_collection_or_view,
            include: index_includes_collection,
            locals: index_locals,
            meta: request.head? ? [] : index_meta
          }
        end

        def show_success_options_rdf
          opts = show_success_options.except(:locals)
          opts[:meta] = request.head? ? [] : show_meta
          opts
        end

        def show_meta
          []
        end

        def update_success_options_rdf
          opts = update_success_options
          opts[:meta] = update_meta
          opts
        end

        def update_meta
          []
        end
      end
    end
  end
end
