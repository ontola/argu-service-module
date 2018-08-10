# frozen_string_literal: true

class ActionItem
  include ActiveModel::Model
  include ActiveModel::Serialization
  include Iriable
  include Ldable

  attr_accessor :type, :parent, :policy, :policy_arguments, :policy_resource,
                :tag, :resource, :result, :image, :url, :http_method, :collection, :form, :iri_template
  attr_writer :label, :target, :description, :iri_template_opts
  delegate :user_context, to: :parent

  def as_json(_opts = {})
    {}
  end

  def iri(only_path: false)
    return iri_from_parent(only_path: only_path) unless iri_template

    RDF::URI(
      [
        expand_uri_template(iri_template, iri_template_opts(parent_iri: resource.iri.path, only_path: only_path)),
        iri_query
      ].compact.join('?')
    )
  end

  alias id iri

  def description
    @description ||
      I18n.t("actions.#{resource&.class_name}.#{tag}.description", default: [:"actions.default.#{tag}.description", ''])
  end

  def label
    @label ||
      I18n.t("actions.#{resource&.class_name}.#{tag}.label",
             default: [:"actions.default.#{tag}.label", tag.to_s.humanize])
  end

  def target
    return @target if @target.present?
    return unless policy.blank? || policy_valid?
    @target = EntryPoint.new(parent: self)
  end

  private

  def iri_from_parent(only_path: false)
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

  def iri_query
    resource.iri.query&.split('&')&.reject { |query| query.include?('type=') }&.join('&')&.presence
  end

  def iri_template_opts(opts = {})
    (@iri_template_opts || {}).merge(opts)
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
