# frozen_string_literal: true

class ActionItem
  include ActiveModel::Model
  include ActiveModel::Serialization
  include Iriable
  include Ldable

  attr_accessor :parent, :policy_arguments, :policy_resource, :resource, :iri_template, :submit_label
  attr_writer :target
  delegate :user_context, to: :parent
  alias iri_template_name iri_template

  %i[description result type policy label image url collection form
     tag http_method iri_template_opts favorite].each do |method|
    attr_writer method
    define_method method do
      var = instance_variable_get(:"@#{method}")
      value = var.respond_to?(:call) ? parent.instance_exec(&var) : var
      return value if value
      send("#{method}_fallback") if respond_to?("#{method}_fallback", true)
    end
  end

  def action_status
    return NS::SCHEMA[:PotentialActionStatus] if policy_valid?
    return NS::ARGU[:ExpiredActionStatus] if policy_expired?
    NS::ARGU[:DisabledActionStatus]
  end

  def as_json(_opts = {})
    {}
  end

  def iri_path(_opts = {})
    return iri_path_from_parent unless iri_template
    [iri_path_from_template(parent_iri: resource.iri_path.split('?').first), iri_query].compact.join('?')
  end

  alias id iri

  def target
    return @target if @target.present?
    return unless policy_valid?
    @target = EntryPoint.new(parent: self)
  end

  private

  def description_fallback
    I18n.t("actions.#{resource&.class_name}.#{tag}.description", default: [:"actions.default.#{tag}.description", ''])
  end

  def iri_path_from_parent
    base = URI(parent.iri_path)
    if parent.is_a?(Actions::Base)
      base.path += "/#{tag}"
    elsif base.include?('#')
      base.fragment = "#{base.fragment}.#{tag}"
    else
      base.fragment = tag
    end
    base.to_s
  end

  def iri_query
    resource.iri.query&.split('&')&.reject { |query| query.include?('type=') }&.join('&')&.presence
  end

  def iri_opts(opts = {})
    (iri_template_opts || {}).merge(opts)
  end

  def label_fallback
    I18n.t("actions.#{resource&.class_name}.#{tag}.label",
           default: [:"actions.default.#{tag}.label", tag.to_s.humanize])
  end

  def policy_expired?
    @policy_expired ||= policy && resource_policy(policy_resource).try(:has_expired_ancestors?)
  end

  def policy_valid?
    return true if policy.blank?
    @policy_valid ||= resource_policy(policy_resource).send(policy, *policy_arguments)
  end

  def resource_policy(policy_resource)
    policy_resource ||= resource
    @resource_policy ||= {}
    @resource_policy[policy_resource.identifier] ||= Pundit.policy(user_context, policy_resource)
  end
end
