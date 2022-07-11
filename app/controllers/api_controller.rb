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

  before_action :set_locale

  private

  def api
    @api ||= Argu::API.new(user_token: user_token)
  end

  def set_locale
    I18n.locale = current_user&.language || ActsAsTenant.current_tenant.language || I18n.default_locale
  end

  def success_message_translation_opts
    super.merge(
      type: I18n.t("#{current_resource.model_name.collection}.type").capitalize
    )
  end
end
