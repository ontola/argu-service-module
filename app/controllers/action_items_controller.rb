# frozen_string_literal: true

class ActionItemsController < AuthorizedController
  include NestedResourceHelper
  skip_before_action :check_if_registered
  before_action :authorize_action

  private

  def authorize_action
    skip_verify_policy_scoped(true)
    if parent_id_from_params.present?
      authorize parent_resource!, :show?
    else
      skip_verify_policy_authorized(true)
    end
  end

  def current_forum; end

  def include_index_collection
    [:target, actions: [target: {action_body: :referred_shapes}]]
  end

  def include_show
    [:object].concat(inc_action_form)
  end

  def index_response_association
    if parent_id_from_params.present?
      parent_resource!.actions(user_context)
    else
      ApplicationActions.new(user_context: user_context).actions
    end
  end

  def resource_by_id
    sym_id = params[:id].to_sym
    if parent_resource.present?
      parent_resource.action(user_context, sym_id)
    else
      ApplicationActions.new(user_context: user_context).action[sym_id]
    end
  end

  def parent_resource
    super if parent_id_from_params.present?
  end

  def tree_root_id
    parent_resource.try(:root_id)
  end
end
