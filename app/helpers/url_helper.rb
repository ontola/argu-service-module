# frozen_string_literal: true

module UrlHelper
  include ServiceHelper

  def argu_url(path = '', params = {})
    url = URI(Rails.application.config.origin)
    url.path = path
    url.fragment = params.delete(:fragment)
    url.query = params.to_param if params.present?
    url.to_s
  end
end
