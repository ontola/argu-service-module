# frozen_string_literal: true

module Argu
  module Controller
    module Common
      # The most commonly used response handlers per response format
      # Methods are named using their numbered counterpart for brevity
      #   and consistency.
      module Responses
        def meta
          respond_to?("meta_#{action_name}", :include_private) ? send("meta_#{action_name}") : []
        end

        # Method to determine where the action should redirect to after it fails.
        # @param [Class] resource The resource from the result of the action
        def redirect_model_failure(resource)
          resource
        end

        # Method to determine where the action should redirect to after it succeeds.
        # @param [Class] resource The resource from the result of the action
        def redirect_model_success(resource)
          resource.persisted? ? resource.iri(only_path: true).to_s : resource.parent.iri(only_path: true).to_s
        end

        def respond_with_200(resource, format, opts = {})
          case format
          when :json, :json_api
            render opts.merge(json: resource)
          when *RDF_CONTENT_TYPES
            render opts.merge(format => resource, meta: meta)
          else
            raise_unknown_format
          end
        end

        # rubocop:disable Metrics/MethodLength
        def respond_with_201(resource, format, opts = {})
          response.headers['Location'] = resource.try(:iri)&.value
          case format
          when :json, :json_api
            render json: resource, status: :created, location: resource.iri.to_s
          when :js
            head :created
          when *RDF_CONTENT_TYPES
            render opts.merge(format => resource, status: :created, meta: meta)
          else
            raise_unknown_format
          end
        end
        # rubocop:enable Metrics/MethodLength

        def respond_with_204(_, format)
          case format
          when :json, :json_api
            head :no_content
          when *RDF_CONTENT_TYPES
            meta.present? ? render(format => [], meta: meta) : head(:no_content)
          else
            raise_unknown_format
          end
        end

        def respond_with_304(_, format)
          case format
          when :json, :json_api, *RDF_CONTENT_TYPES
            head 304
          else
            raise_unknown_format
          end
        end

        def respond_with_400(resource, format) # rubocop:disable Metrics/MethodLength
          case format
          when :json
            render json: resource.errors, status: :bad_request
          when :json_api
            render json_api_error(400, resource.errors)
          when :js
            head 400
          when *RDF_CONTENT_TYPES
            render format => serializable_error(400, StandardError.new(resource.errors.full_messages.join("\n"))),
                   status: 400
          else
            raise_unknown_format
          end
        end

        def respond_with_422(resource, format) # rubocop:disable Metrics/MethodLength
          case format
          when :json
            render json_error(422, resource.errors)
          when :json_api
            render json_api_error(422, resource.errors)
          when *RDF_CONTENT_TYPES
            render format => serializable_error(422, StandardError.new(resource.errors.full_messages.join("\n"))),
                   status: 422
          else
            raise_unknown_format
          end
        end

        def respond_with_form(resource)
          render :form, locals: {model_name => resource}
        end

        def respond_with_form_js(resource)
          respond_js(
            "#{controller_name}/form",
            resource: resource,
            controller_name.singularize.to_sym => resource
          )
        end

        def respond_js(view, locals)
          render 'container_replace', locals: {view: view, locals: locals}
        end

        # @param resource [ActiveRecord::Base] The resource to redirect to.
        # @param _ [Symbol] The action to render the message for.
        def respond_with_redirect_failure(resource, _)
          redirect_with_message redirect_model_failure(resource),
                                message_failure
        end

        # @param resource [ActiveRecord::Base] The resource to redirect to.
        # @param action [Symbol] The action to render the message for.
        def respond_with_redirect_success(resource, action, opts = {})
          redirect_with_message redirect_model_success(resource),
                                message_success(resource, action),
                                opts
        end

        def respond_with_redirect_success_js(resource, action)
          flash[:notice] = message_success(resource, action)
          render 'turbolinks_redirect', locals: {location: redirect_model_success(resource)}
        end

        private

        def raise_unknown_format
          raise t('errors.unknown_format')
        end

        def redirect_with_message(location, message, opts = {})
          redirect_to location, opts.merge(notice: message.capitalize)
        end

        def lookup_template(file)
          if lookup_context.exists?("#{controller_path}/#{file}.html")
            "#{controller_path}/#{file}.html"
          else
            "application/#{file}.html"
          end
        end

        def message_failure
          t('errors.general')
        end

        # @param resource [ActiveRecord::Base] The resource to display the type for.
        # @param action [Symbol] The action to render the message for.
        def message_success(r, action)
          if action.to_sym == :create && r.try(:argu_publication)&.publish_time_lapsed?
            t('type_publish_success', type: type_for(r)).capitalize
          else
            t("type_#{action}_success", type: type_for(r)).capitalize
          end
        end

        def meta_replace_collection_count(data, collection)
          data.push [collection.iri, NS::ARGU[:members], nil, NS::LL[:remove]]
          data.push [collection.iri, NS::ARGU[:totalCount], collection.total_count, NS::LL[:replace]]
        end
      end
    end
  end
end
