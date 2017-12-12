# frozen_string_literal: true

class ActionsController < AuthorizedController
  include NestedResourceHelper
  skip_before_action :check_if_registered
  before_action :authorize_action

  def show
    respond_to do |format|
      format.json_api { render json: resource_by_id!, include: include_show }
      format.nt { render nt: resource_by_id!, include: include_show }
    end
  end

  private

  def authenticated_tree
    parent_resource.try(:edge)&.self_and_ancestors
  end

  def authorize_action
    skip_verify_policy_scoped(true)
    if parent_resource.present?
      authorize parent_resource, :show?
    else
      skip_verify_policy_authorized(true)
    end
  end

  def current_forum; end

  def include_index
    [actions: :target]
  end

  def include_show
    [actions: :target]
  end

  def index_response_association
    if parent_resource.present?
      parent_resource.actions(user_context)
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
end
