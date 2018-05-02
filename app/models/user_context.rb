# frozen_string_literal: true

class UserContext
  attr_reader :user, :actor, :doorkeeper_scopes, :tree_root_id

  def initialize(user: nil, doorkeeper_scopes: nil, profile: nil, tree_root_id: nil)
    @user = user
    @profile = profile
    @doorkeeper_scopes = doorkeeper_scopes
    @tree_root_id = tree_root_id
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
