# frozen_string_literal: true

class RestrictivePolicy
  include LinkedRails::Policy

  class Scope
    attr_reader :user_context, :scope

    def initialize(user_context, scope)
      @user_context = user_context
      @scope = scope
    end

    def resolve; end
  end

  attr_reader :user_context, :record

  delegate :export_scope?, :service_scope?, :system_scope?,
           to: :user_context,
           allow_nil: true

  def initialize(user_context, record)
    @user_context = user_context
    @record = record
  end

  def api_authorization(**opts)
    user_context.api.authorize_action(**opts)
  rescue OAuth2::Error => e
    error = parse_api_error(e) || {}
    status = RDF::URI(error['action_status']) if error['action_status']

    forbid_with_message(error['message'], status)
  end

  def create?
    false
  end

  def delete?
    destroy?
  end

  def destroy?
    false
  end

  def edit?
    update?
  end

  def index?
    false
  end

  def new?
    create?
  end

  def show?
    false
  end

  def update?
    false
  end

  def parse_api_error(error)
    JSON.parse(error.body)['errors'].try(:first) if error.body.present?
  end
end
