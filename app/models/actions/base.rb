# frozen_string_literal: true

module Actions
  class Base
    include ActiveModel::Model
    include RailsLD::Model

    class_attribute :defined_actions
    attr_accessor :resource, :user_context
    delegate :user, to: :user_context

    alias read_attribute_for_serialization send
    alias current_user user_context

    def iri_path(opts = {})
      parent_iri = URI(resource_iri_path)
      query = parent_iri.query
      parent_iri.query = nil
      i = URI(expand_uri_template('action_lists_iri', opts.merge(parent_iri: parent_iri)))
      i.query = query
      i.to_s
    end

    def actions
      @actions ||=
        defined_actions
          .keys
          .map { |tag| action(tag) }
    end

    def action(tag)
      @action ||= {}
      @action[tag] ||= action_item(tag, defined_actions[tag].dup)
    end

    def self.define_action(action, opts = {})
      self.defined_actions ||= {}
      opts[:collection] ||= false
      self.defined_actions[action] = opts
    end

    def defined_actions
      self.class.defined_actions&.select { |_tag, opts| collection_filter(opts) } || {}
    end

    private

    def action_condition(opts)
      opts[:if].blank? || instance_exec(&opts[:if])
    end

    def action_item(tag, options)
      target = options[:resource] ? instance_exec(&options.delete(:resource)) : resource
      ActionItem.new(resource: target, tag: options[:action_tag] || tag, parent: self, **options.except(:action_tag))
    end

    def call_option(option)
      option.respond_to?(:call) ? instance_exec(&option) : option
    end

    def collection_filter(opts)
      call_option(opts[:collection]) == resource.is_a?(Collection)
    end

    def resource_iri_path
      resource.iri_path
    end
  end
end
