# frozen_string_literal: true

module Actions
  class Base
    include ActiveModel::Model
    include Ldable
    include Iriable
    include ActionDispatch::Routing
    include Rails.application.routes.url_helpers

    class_attribute :defined_actions
    attr_accessor :resource, :user_context
    delegate :user, to: :user_context

    alias read_attribute_for_serialization send
    alias current_user user_context

    def iri(opts = {})
      parent_iri = resource_path_iri
      query = parent_iri.query
      parent_iri.query = nil
      i = RDF::URI(expand_uri_template('action_lists_iri', opts.merge(parent_iri: parent_iri)))
      i.query = query
      i
    end

    def actions
      defined_actions
        &.select { |_tag, opts| opts[:collection] == resource.is_a?(Collection) }
        &.keys
        &.map { |tag| action(tag) }
    end

    def action(tag)
      @action ||= {}
      return @action[tag] if @action.key?(tag)
      opts = defined_actions.select { |_tag, options| options[:collection] == resource.is_a?(Collection) }[tag].dup
      opts.each do |key, value|
        opts[key] = instance_exec(&value) if value.respond_to?(:call)
      end
      @action[tag] = action_item(tag, opts)
    end

    def self.define_action(action, opts = {})
      self.defined_actions ||= {}
      opts[:collection] ||= false
      self.defined_actions[action] = opts
    end

    private

    def action_item(tag, options)
      ActionItem.new(resource: resource, tag: options[:action_tag] || tag, parent: self, **options.except(:action_tag))
    end

    def create_url(resource)
      return resource.parent_view_iri if paged_resource?(resource)
      resource.iri
    end

    def paged_resource?(resource)
      resource.is_a?(Collection) && resource.pagination && resource.page.present?
    end

    def resource_collection(col_name)
      resource.send("#{col_name}_collection".to_sym, user_context: user_context)
    end

    def resource_path_iri
      resource.iri(only_path: true)
    end
  end
end
