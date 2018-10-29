# frozen_string_literal: true

require_relative 'service_helper'

module UrlHelper
  include ServiceHelper

  def argu_url(path = '', params = {})
    url = URI(params.delete(:frontend) ? Rails.application.config.frontend_url : Rails.application.config.origin)
    url.path = path
    url.fragment = params.delete(:fragment)
    url.query = params.to_param if params.present?
    url.to_s
  end
end
