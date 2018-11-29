# frozen_string_literal: true

require 'uri_template'
require 'argu'

class ApiController < ActionController::API
  include ActiveResponse::Controller
  include Argu::Controller::Authentication
  include Argu::Controller::Authorization
  include Argu::Controller::ErrorHandling
  include RailsLD::ActiveResponse::Controller::CrudDefaults

  include ActionController::MimeResponds
  include JsonApiHelper
  include UrlHelper
  serialization_scope :user_context

  force_ssl unless: :internal_request?
  before_action :set_locale

  private

  def api
    @api ||= Argu::API.new(
      service_token: ENV['SERVICE_TOKEN'],
      user_token: user_token,
      cookie_jar: request.cookie_jar
    )
  end

  def internal_request?
    Argu::WhitelistConstraint.matches?(request)
  end

  def set_locale
    I18n.locale = current_user&.language&.gsub("#{NS::ARGU[:locale]}/", '') || I18n.default_locale
  end
end
