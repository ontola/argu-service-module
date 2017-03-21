# frozen_string_literal: true
require 'uri_template'
require 'oauth2'
require 'argu/errors/unauthorized_error'
require 'argu/errors/forbidden_error'

class ApiController < ActionController::API
  include UrlHelper, JsonApiHelper, ActionController::MimeResponds
  AUTH_URL = URITemplate.new('/spi/authorize{?resource_type,resource_id,authorize_action}')
  serialization_scope :nil

  rescue_from Errors::UnauthorizedError, with: :handle_unauthorized_error
  rescue_from Errors::ForbiddenError, with: :handle_forbidden_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found_error
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from OAuth2::Error, with: :handle_oauth_error

  def current_user
    return @current_user if @current_user.present?
    response = argu_token.get('/spi/current_user')
    @current_user = OpenStruct.new(JSON.parse(response.body)['data']['attributes']) if response.status == 200
  end

  private

  def argu_client
    @argu_client ||= OAuth2::Client.new(
      ENV['ARGU_APP_ID'],
      ENV['ARGU_APP_SECRET'],
      site: ENV['OAUTH_URL']
    )
  end

  def argu_token
    @argu_token ||= OAuth2::AccessToken.new(argu_client, client_token)
  end

  def authorize_action(resource_type, resource_id, action)
    argu_token.get(AUTH_URL.expand(resource_type: resource_type, resource_id: resource_id, authorize_action: action))
  end

  def check_if_registered
    raise Errors::UnauthorizedError if current_user.blank?
  end

  def client_token
    ENV['CLIENT_TOKEN']
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
      format.html { render_status e.response.status }
      format.json_api { render json_api_error(e.response.status, e.response.body) }
    end
  end

  def handle_parameter_missing(e)
    raise unless request.format.json_api?
    render json_api_error(400, e.message)
  end

  def handle_record_not_found_error
    respond_to do |format|
      format.html { render_status 404 }
      format.json_api { render json_api_error(404, 'The requested resource could not be found') }
    end
  end

  def handle_unauthorized_error
    respond_to do |format|
      format.html { render_status 401 }
      format.json_api { render json_api_error(401, 'Please sign in to continue') }
    end
  end

  def render_status(status, file_name = nil)
    file_name ||= "status/#{status}"
    send_file lookup_context.find_template(file_name).identifier, disposition: :inline, status: status
  end
end
