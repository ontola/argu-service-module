# frozen_string_literal: true

class UserContext
  attr_reader :api, :user, :actor, :doorkeeper_token, :tree_root_id

  delegate :guest?, to: :user

  def initialize(api: nil, user: nil, doorkeeper_token: nil, profile: nil, tree_root_id: nil)
    @api = api
    @user = user
    @profile = profile
    @doorkeeper_token = doorkeeper_token
    @tree_root_id = tree_root_id
  end

  def doorkeeper_scopes
    doorkeeper_token&.scopes
  end

  def export_scope?
    doorkeeper_scopes&.include? 'export'
  end

  def service_scope?
    doorkeeper_scopes&.include? 'service'
  end

  def system_scope?
    service_scope? || export_scope?
  end
end
