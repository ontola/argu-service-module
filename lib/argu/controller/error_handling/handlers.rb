# frozen_string_literal: true

module Argu
  module Controller
    # The generic Argu error handling code. Currently a mess from different error
    # classes with inconsistent attributes.
    module ErrorHandling
      module Handlers
        include LinkedRails::Helpers::OntolaActionsHelper

        def error_response_json(error, status: nil)
          render json_error(status || error_status(error), json_error_hash(error))
        end

        def error_response_json_api(error, status: nil)
          render json_api_error(status || error_status(error), json_error_hash(error))
        end

        def handle_and_report_error(error)
          raise if Rails.env.development? || Rails.env.test?

          Bugsnag.notify(error)
          raise if response_body

          handle_error(error)
        end

        def handle_error(error)
          error_mode(error)
          respond_to do |format|
            format.json { error_response_json(error) }
            format.json_api { error_response_json_api(error) }
            RDF_CONTENT_TYPES.each { |type| format.send(type) { error_response_serializer(error, type) } }
            format.any { head(error_status(error)) }
          end
        end

        def error_response(error, format)
          method = "handle_#{error.class.name.demodulize.underscore}_#{format}"
          respond_to?(method, :include_private) ? send(method, error) : send("error_response_#{format}", error)
        end

        def handle_oauth_error(error)
          Bugsnag.notify(error)
          handle_error(StandardError.new(error.response.body))
        end

        def respond_with_422?(resources)
          resources.any? { |r| r.is_a?(ActiveModel::Errors) || r.respond_to?(:errors) && r.errors.present? }
        end
      end
    end
  end
end
