# frozen_string_literal: true

class ActionItem
  include ActiveModel::Model
  include ActiveModel::Serialization
  include Iriable
  include Ldable

  attr_accessor :parent, :policy_arguments, :policy_resource, :resource, :iri_template
  attr_writer :target, :iri_template_opts
  delegate :user_context, to: :parent
  alias iri_template_name iri_template

  %i[description result type policy label image url collection form tag http_method].each do |method|
    attr_writer method
    define_method method do
      value = instance_variable_get(:"@#{method}") ||
        respond_to?("#{method}_fallback", true) && send("#{method}_fallback") ||
        nil
      value.respond_to?(:call) ? parent.instance_exec(&value) : value
    end
  end

  def as_json(_opts = {})
    {}
  end

  def iri_path(_opts = {})
    return iri_path_from_parent unless iri_template
    [iri_path_from_template(parent_iri: resource.iri.path), iri_query].compact.join('?')
  end

  alias id iri

  def target
    return @target if @target.present?
    return unless policy.blank? || policy_valid?
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
    (@iri_template_opts || {}).merge(opts)
  end

  def label_fallback
    I18n.t("actions.#{resource&.class_name}.#{tag}.label",
           default: [:"actions.default.#{tag}.label", tag.to_s.humanize])
  end

  def policy_valid?
    resource_policy(policy_resource).send(policy, *policy_arguments)
  end

  def resource_policy(policy_resource)
    policy_resource ||= resource
    @resource_policy ||= {}
    @resource_policy[policy_resource.identifier] ||= Pundit.policy(user_context, policy_resource)
  end
end
