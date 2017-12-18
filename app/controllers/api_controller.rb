# frozen_string_literal: true

require 'uri_template'
require 'argu/api'
require 'argu/errors/unauthorized_error'
require 'argu/errors/forbidden_error'

class ApiController < ActionController::API
  include ActionController::MimeResponds
  include JsonApiHelper
  include UrlHelper
  serialization_scope :nil

  rescue_from Errors::UnauthorizedError, with: :handle_unauthorized_error
  rescue_from Errors::ForbiddenError, with: :handle_forbidden_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found_error
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from OAuth2::Error, with: :handle_oauth_error

  class_attribute :inc_nested_collection
  self.inc_nested_collection = [
    member_sequence: :members,
    operation: :target,
    view_sequence: [
      members:
        [
          member_sequence: :members,
          operation: :target,
          view_sequence: [members: [member_sequence: :members, operation: :target].freeze].freeze
        ].freeze
    ].freeze
  ].freeze

  def current_user
    @current_user ||= CurrentUser.find(request.cookie_jar.encrypted['argu_client_token'])
  rescue OAuth2::Error
    nil
  end

  private

  def api
    @api ||= Argu::API.new(
      service_token: ENV['SERVICE_TOKEN'],
      user_token: request.cookie_jar.encrypted['argu_client_token'],
      cookie_jar: request.cookie_jar
    )
  end

  def authorize_action(resource_type, resource_id, action)
    api.authorize_action(resource_type, resource_id, action)
  end

  def check_if_registered
    raise Errors::UnauthorizedError if current_user.blank?
  end

  def handle_forbidden_error
    respond_to do |format|
      format.html { render_status 403 }
      format.json_api { render json_api_error(403, 'You are not authorized for this action') }
    end
  end

  def handle_oauth_error(e)
    case e.response.status
    when 401
      handle_unauthorized_error
    when 403
      handle_forbidden_error
    else
      handle_general_oauth_error(e)
    end
  end

  def handle_general_oauth_error(e)
    Bugsnag.notify(e)
    respond_to do |format|
      format.html { render_status 500 }
      format.json { render status: 500 }
      format.json_api { render json_api_error(500, e.response.body) }
    end
  end

  def handle_parameter_missing(e)
    raise unless request.format.json_api?
    render json_api_error(400, e.message)
  end

  def handle_record_not_found_error
    respond_to do |format|
      format.html { render_status 404 }
      format.json { render status: 404 }
      format.json_api { render json_api_error(404, 'The requested resource could not be found') }
    end
  end

  def handle_unauthorized_error
    respond_to do |format|
      format.html { render_status 401 }
      format.json { render status: 401 }
      format.json_api { render json_api_error(401, 'Please sign in to continue') }
    end
  end

  def render_status(status, file_name = nil)
    file_name ||= "status/#{status}"
    send_file lookup_context.find_template(file_name).identifier, disposition: :inline, status: status
  end
end
