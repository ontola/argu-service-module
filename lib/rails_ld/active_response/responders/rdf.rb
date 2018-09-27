# frozen_string_literal: true

require_relative '../rdf_error'
require 'active_response/responders/html'

module RailsLD
  module ActiveResponse
    module Responders
      class RDF < ::ActiveResponse::Responders::HTML
        respond_to(*RDF_CONTENT_TYPES)

        def collection(opts)
          opts[:resource] = opts.delete(:collection)
          controller.respond_with_resource opts
        end

        def destroyed(opts)
          response_headers(opts)
          if opts[:meta].present?
            controller.render(format => [], meta: opts[:meta])
          else
            controller.head 200
          end
        end

        def form(**opts)
          response_headers(opts)
          controller.respond_with_resource(
            resource: opts[:action],
            include: opts[:include]
          )
        end

        def invalid_resource(**opts)
          errors = opts[:resource].is_a?(ActiveModel::Errors) ? opts[:resource] : opts[:resource].errors
          message = errors.full_messages.join("\n")
          response_headers(opts.merge(notice: message))
          controller.render(
            format => error_graph(StandardError.new(message), 422),
            status: :unprocessable_entity
          )
        end

        def new_resource(**opts)
          opts[:status] = :created
          response_headers(opts)
          controller.respond_with_resource(opts)
        end

        def redirect(**opts)
          response_headers(opts)
          controller.head 200
        end

        def resource(**opts)
          response_headers(opts)
          if opts[:resource].blank?
            controller.head 200
          else
            opts[format] = opts.delete(:resource)
            controller.render opts
          end
        end

        def updated_resource(**opts)
          response_headers(opts)
          if opts[:meta].present?
            controller.render(format => [], meta: opts[:meta])
          else
            controller.head 200
          end
        end

        private

        def error_graph(error, status)
          RailsLD::ActiveResponse::RDFError
            .new(status, controller.request.original_url, error.is_a?(StandardError) ? error : error.new)
            .graph
        end

        def response_headers(opts)
          headers = controller.response.headers
          if opts[:location].present?
            add_exec_action_header(headers, NS::ONTOLA["actions/redirect?location=#{opts[:location]}"])
          end
          return if opts[:notice].blank?
          add_exec_action_header(headers, NS::ONTOLA["actions/snackbar?text=#{ERB::Util.url_encode(opts[:notice])}"])
        end

        def add_exec_action_header(headers, action)
          headers['Exec-Action'] ||= ''
          headers['Exec-Action'] += "#{action}\n"
        end
      end
    end
  end
end
