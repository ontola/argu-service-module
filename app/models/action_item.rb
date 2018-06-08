# frozen_string_literal: true

class ActionItem
  include ActiveModel::Model
  include ActiveModel::Serialization
  include Iriable
  include Ldable

  attr_accessor :type, :parent, :policy, :policy_arguments, :policy_resource,
                :tag, :resource, :result, :image, :url, :http_method, :collection
  attr_writer :label, :target

  def as_json(_opts = {})
    {}
  end

  def iri(only_path: false)
    base = parent.iri(only_path: only_path)

    if parent.is_a?(Actions::Base)
      base.path += "/#{tag}"
    elsif parent.iri.to_s.include?('#')
      base.fragment = "#{base.fragment}.#{tag}"
    else
      base.fragment = tag
    end
    RDF::URI(base)
  end

  alias id iri

  def label
    @label ||
      I18n.t("actions.#{resource&.class_name}.#{tag}", default: ["actions.default.#{tag}".to_sym, tag.to_s.humanize])
  end

  def target
    return @target if @target.present?
    return unless policy.blank? || policy_valid?
    @target = EntryPoint.new(parent: self)
  end

  private

  def policy_valid?
    resource_policy(policy_resource).send(policy, *policy_arguments)
  end

  def resource_policy(policy_resource)
    policy_resource ||= resource
    @resource_policy ||= {}
    @resource_policy[policy_resource.identifier] ||= Pundit.policy(parent.user_context, policy_resource)
  end
end
