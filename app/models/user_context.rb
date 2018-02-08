# frozen_string_literal: true

class UserContext
  attr_reader :user, :doorkeeper_scopes

  def initialize(user, doorkeeper_scopes)
    @user = user
    @doorkeeper_scopes = doorkeeper_scopes
  end
end
