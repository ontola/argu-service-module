# frozen_string_literal: true

class CollectionPolicy < RestrictivePolicy
  def create_child?
    parent_policy&.create_child?(record.association_class.name.tableize.to_sym)
  end

  private

  def parent_policy
    return if record.parent.blank?
    @parent_policy ||= Pundit.policy(context, record.parent)
  end
end
