# frozen_string_literal: true

require 'uri_template'
require 'argu'

class ApiController < ActionController::API
  include Argu::Controller::ErrorHandling
  include Argu::Controller::Common::Responses

  include ActionController::MimeResponds
  include JsonApiHelper
  include UrlHelper
  serialization_scope :nil

  class_attribute :inc_nested_collection
  self.inc_nested_collection = [
    default_view: {member_sequence: :members},
    filters: []
  ].freeze
  class_attribute :inc_shallow_collection
  self.inc_shallow_collection = [
    filters: []
  ].freeze

  def current_user
    @current_user ||= CurrentUser.find(user_token)
  rescue OAuth2::Error
    nil
  end

  private

  def api
    @api ||= Argu::API.new(
      service_token: ENV['SERVICE_TOKEN'],
      user_token: user_token,
      cookie_jar: request.cookie_jar
    )
  end

  def authorization_header?
    request.headers['Authorization'].present?
  end

  def authorize(resource_iri, action)
    return true if api.authorize_action(resource_iri: resource_iri, action: action)
    raise Argu::Errors::Forbidden.new(query: action)
  end

  def authorize_action(resource_type, resource_id, action)
    return true if api.authorize_action(resource_type: resource_type, resource_id: resource_id, action: action)
    raise Argu::Errors::Forbidden.new(query: action)
  end

  def check_if_registered
    raise Argu::Errors::Unauthorized if current_user.blank?
  end

  def token_from_cookie
    request.cookie_jar.encrypted['argu_client_token']
  end

  def token_from_header
    request.headers['Authorization'][7..-1] if request.headers['Authorization'].downcase.start_with?('bearer ')
  end

  def user_token
    @user_token ||= authorization_header? ? token_from_header : token_from_cookie
  end
end
