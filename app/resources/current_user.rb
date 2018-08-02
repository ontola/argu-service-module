# frozen_string_literal: true

class CurrentUser < ActiveResourceModel
  def self.find(token)
    @token = token
    super(:one, from: '/spi/current_user')
  end

  def self.connection
    OauthConnection.new(OAuth2::AccessToken.new(argu_client, @token))
  end
end
