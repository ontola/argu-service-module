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
end
