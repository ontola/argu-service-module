# frozen_string_literal: true

require 'rails_ld/active_response/rdf_error'

module Argu
  module Controller
    # The generic Argu error handling code. Currently a mess from different error
    # classes with inconsistent attributes.
    module ErrorHandling
      module Handlers
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
          render type => error_graph(status, e), status: status
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

        def error_graph(status, e)
          RailsLD::ActiveResponse::RDFError.new(status, request.original_url, e.is_a?(StandardError) ? e : e.new).graph
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

        def respond_with(*resources, &_block)
          return super unless respond_with_422?(resources)
          respond_to do |format|
            format.json { respond_with_422(resources.first, :json) }
            format.json_api { respond_with_422(resources.first, :json_api) }
            RDF_CONTENT_TYPES.each do |type|
              format.send(type) { respond_with_422(resources.first, type) }
            end
          end
        end

        def respond_with_422?(resources)
          ![:html, nil].include?(request.format.symbol) &&
            !resources.all? { |r| r.respond_to?(:valid?) ? r.valid? : true }
        end
      end
    end
  end
end
