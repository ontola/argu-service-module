# frozen_string_literal: true

module ActiveResponseHelper
  def create_success_location
    redirect_location
  end

  def destroy_success_location
    redirect_location
  end

  def index_success_options_json_api
    index_success_options_rdf
  end

  def index_success_options_rdf
    skip_verify_policy_scoped(sure: true)
    super
  end

  def redirect_location
    if current_resource.persisted?
      current_resource.iri.to_s
    else
      current_resource.parent.iri.to_s
    end
  end

  def redirect_message
    if action_name == 'create' && current_resource.try(:argu_publication)&.publish_time_lapsed?
      I18n.t('type_publish_success', type: type_for(current_resource)).capitalize
    else
      I18n.t("type_#{action_name}_success", type: type_for(current_resource)).capitalize
    end
  end

  def update_success_location
    redirect_location
  end

  def meta_replace_collection_count(data, collection)
    data.push [collection.iri, NS.as.totalItems, collection.total_count, NS.ld[:replace]]
  end
end
