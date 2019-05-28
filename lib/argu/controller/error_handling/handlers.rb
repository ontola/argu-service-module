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
          request.method != 'GET'
        end

        def error_response_html(e, view: nil)
          respond_to?(:flash) && flash[:alert] = e.message
          status ||= error_status(e)
          view ||= "status/#{status}"
          send_file lookup_context.find_template(view).identifier, disposition: :inline, status: status
        end

        def error_response_js(e, status: nil)
          status ||= error_status(e)
          render status: status, json: json_error_hash(e)
        end

        def error_response_json(e, status: nil)
          render json_error(status ||  error_status(e), json_error_hash(e))
        end

        def error_response_json_api(e, status: nil)
          render json_api_error(status || error_status(e), json_error_hash(e))
        end

        def error_response_serializer(e, type, status: nil)
          status ||= error_status(e)
          error = error_resource(status, e)
          add_error_snackbar(error) if add_error_snackbar?(error)
          render type => error.graph, status: status
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
            format.html { error_response(e, :html) }
            format.js { error_response(e, :js) }
            format.json { error_response_json(e) }
            format.json_api { error_response_json_api(e) }
            RDF_CONTENT_TYPES.each do |type|
              format.send(type) { error_response_serializer(e, type) }
            end
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

        def handle_record_not_unique_html(_e)
          flash[:warning] = t('errors.record_not_unique')
          redirect_back(fallback_location: root_path)
        end

        def respond_with_422?(resources)
          resources.any? { |r| r.is_a?(ActiveModel::Errors) || r.respond_to?(:errors) && r.errors.present? }
        end
      end
    end
  end
end
