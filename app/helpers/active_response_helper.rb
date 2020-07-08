# frozen_string_literal: true

module ActiveResponseHelper
  ACTION_MAP = {
    edit: :update,
    bin: :trash,
    unbin: :untrash,
    delete: :destroy,
    new: :create,
    shift: :move
  }.freeze

  def active_response_action(opts)
    action_resource = opts[:resource].try(:new_record?) ? index_collection : opts[:resource]
    form = active_response_action_name(opts)
    action_resource.action(user_context, ACTION_MAP[form.to_sym] || form.to_sym) if form
  end

  def active_response_action_name(opts)
    form = params[:form] || opts[:view]
    form == 'form' ? action_name : form
  end

  def create_meta
    data = super
    return data if index_collection.blank?

    meta_replace_collection_count(data, index_collection.unfiltered)
    data
  end

  def create_success_location
    redirect_location
  end

  def default_form_view(action)
    if lookup_context.exists?("#{controller_path}/#{action}")
      action
    elsif lookup_context.exists?("application/#{action}")
      "application/#{action}"
    else
      'form'
    end
  end

  def default_form_view_locals(_action)
    {
      controller_name.singularize.to_sym => current_resource,
      resource: current_resource
    }
  end

  def destroy_meta
    data = super
    return data if index_collection.blank?

    meta_replace_collection_count(data, index_collection.unfiltered)
    data
  end

  def destroy_success_location
    redirect_location
  end

  def index_association
    @index_association ||= policy_scope(super)
  end

  def index_success_options_json_api
    index_success_options_rdf
  end

  def index_success_options_rdf
    skip_verify_policy_scoped(true) if index_collection_or_view.present?
    super
  end

  def redirect_location
    current_resource.persisted? ? current_resource.iri_path : current_resource.parent.iri_path
  end

  def redirect_message
    if action_name == 'create' && current_resource.try(:argu_publication)&.publish_time_lapsed?
      I18n.t('type_publish_success', type: type_for(current_resource)).capitalize
    else
      I18n.t("type_#{action_name}_success", type: type_for(current_resource)).capitalize
    end
  end

  def show_view_locals
    {
      controller_name.singularize.to_sym => current_resource,
      resource: current_resource
    }
  end

  def update_success_location
    redirect_location
  end

  def meta_replace_collection_count(data, collection)
    data.push [collection.iri, NS::AS[:totalItems], collection.total_count, NS::LL[:replace]]
  end
end
