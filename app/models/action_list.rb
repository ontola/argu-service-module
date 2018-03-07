# frozen_string_literal: true

class ActionList
  include ActiveModel::Model
  include Ldable
  include Iriable
  include ActionDispatch::Routing
  include Rails.application.routes.url_helpers
  include Pundit

  attr_accessor :resource, :user_context
  delegate :user, to: :user_context

  alias read_attribute_for_serialization send
  alias current_user user_context

  def iri(opts = {})
    parent_iri = resource.iri(only_path: true)
    query = parent_iri.query
    parent_iri.query = nil
    i = RDF::URI(expand_uri_template('action_lists_iri', opts.merge(parent_iri: parent_iri)))
    i.query = query
    i
  end

  def self.define_actions(actions)
    self.defined_actions = actions
  end

  def actions
    defined_actions.map { |action| send("#{action}_action") }.compact
  end

  def action
    Hash[defined_actions.map { |action| [action, send("#{action}_action")] }]
  end

  private

  def action_item(tag, options)
    ActionItem.new(resource: resource, tag: tag, parent: self, **options)
  end

  def default_action_label(tag, options)
    I18n.t("actions.#{resource&.class_name}.#{tag}",
           options[:label_params]
             .merge(default: ["actions.default.#{tag}".to_sym, tag.to_s.capitalize]))
  end

  def entry_point_item(tag, options)
    return unless options[:policy].blank? || policy_valid?(options)

    options[:label_params] ||= {}
    options[:label] ||= default_action_label(tag, options)
    options[:entrypoints]&.flatten!
    options.except!(:policy_resource, :policy, :policy_arguments)

    EntryPoint.new(resource: resource, tag: tag, parent: self, **options)
  end

  def policy_valid?(options)
    resource_policy(options[:policy_resource]).send(options[:policy], *options[:policy_arguments])
  end

  def resource_policy(policy_resource)
    policy_resource ||= resource
    @resource_policy ||= {}
    @resource_policy[policy_resource.identifier] ||= policy(policy_resource)
  end
end
