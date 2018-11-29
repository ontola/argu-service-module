# frozen_string_literal: true

class RestrictivePolicy
  class Scope
    attr_reader :context, :scope

    def initialize(context, scope)
      @context = context
      @scope = scope
    end

    def resolve; end
  end

  attr_reader :context, :record

  def initialize(context, record)
    @context = context
    @record = record
  end

  def create?
    false
  end

  def create_child?(_raw_klass)
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
