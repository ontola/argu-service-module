# frozen_string_literal: true
module UrlHelper
  def argu_url(path = '', params = {})
    url = URI("https://#{Rails.application.config.host_name}")
    url.path = path
    url.query = params.to_param if params.present?
    url.to_s
  end
end
