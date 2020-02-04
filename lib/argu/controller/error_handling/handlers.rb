# frozen_string_literal: true

module Argu
  module Controller
    # The generic Argu error handling code. Currently a mess from different error
    # classes with inconsistent attributes.
    module ErrorHandling
      module Handlers
        include LinkedRails::Helpers::OntolaActionsHelper

        def add_error_snackbar(error)
          add_exec_action_header(response.headers, ontola_snackbar_action(error.error.message))
        end

        def add_error_snackbar?(_error)
          !%w[GET HEAD].include?(request.method)
        end

        def error_response_json(e, status: nil)
          render json_error(status || error_status(e), json_error_hash(e))
        end

        def error_response_json_api(e, status: nil)
          render json_api_error(status || error_status(e), json_error_hash(e))
        end

        def handle_and_report_error(e)
          raise if Rails.env.development? || Rails.env.test?
          Bugsnag.notify(e)
          raise if response_body
          handle_error(e)
        end

        def handle_error(e)
          error_mode(e)
          respond_to do |format|
            format.json { error_response_json(e) }
            format.json_api { error_response_json_api(e) }
            RDF_CONTENT_TYPES.each { |type| format.send(type) { error_response_serializer(e, type) } }
            format.any { head(error_status(e)) }
          end
        end

        def error_resource(status, e)
          LinkedRails.rdf_error_class.new(status, request.original_url, e)
        end

        def error_response(e, format)
          method = "handle_#{e.class.name.demodulize.underscore}_#{format}"
          respond_to?(method, :include_private) ? send(method, e) : send("error_response_#{format}", e)
        end

        def handle_oauth_error(e)
          Bugsnag.notify(e)
          handle_error(StandardError.new(e.response.body))
        end

        def respond_with_422?(resources)
          resources.any? { |r| r.is_a?(ActiveModel::Errors) || r.respond_to?(:errors) && r.errors.present? }
        end
      end
    end
  end
end
