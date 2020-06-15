# frozen_string_literal: true

require 'uri_template'
require 'argu'

class APIController < ActionController::API
  include ActiveResponse::Controller
  include LinkedRails::Controller
  include Argu::Controller::Authentication
  include Argu::Controller::Authorization
  include Argu::Controller::ErrorHandling

  include ActionController::MimeResponds
  include JsonAPIHelper
  include UrlHelper
  serialization_scope :user_context

  force_ssl unless: :internal_request?
  before_action :set_locale

  private

  def api
    @api ||= Argu::API.new(
      service_token: ENV['SERVICE_TOKEN'],
      user_token: user_token
    )
  end

  def internal_request?
    Argu::WhitelistConstraint.matches?(request)
  end

  def set_locale
    I18n.locale = current_user&.language || I18n.default_locale
  end

  def success_message_translation_opts
    {type: I18n.t("#{current_resource.model_name.collection}.type").capitalize}
  end
end
