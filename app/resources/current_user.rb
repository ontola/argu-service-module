# frozen_string_literal: true

class CurrentUser < ActiveResourceModel
  def self.find(token)
    @token = token
    super(:one, from: '/spi/current_user')
  end

  def self.connection
    OauthConnection.new(service(:argu, token: @token))
  end
end
