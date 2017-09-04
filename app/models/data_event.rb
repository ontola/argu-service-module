# frozen_string_literal: true

class DataEvent
  include Ldable, JsonApiHelper
  attr_accessor :affected_resources, :changes, :event, :resource, :resource_id, :resource_type
  alias read_attribute_for_serialization send

  def id
    nil
  end

  def initialize(attrs = {})
    attrs.is_a?(Hash) ? parse_json_api(attrs) : parse_resource(attrs)
  end

  def self.parse(body)
    new(JSON.parse(body))
  end

  def self.publish(resource)
    new(resource).publish
  end

  def publish
    Connection.publish('events', json)
  end

  private

  def changes_from_resource
    return unless event == 'update'
    [
      {
        id: resource_id,
        type: resource_type,
        attributes: filtered_attributes(resource.previous_changes)
      }
    ]
  end

  def filtered_attributes(attributes)
    ActionDispatch::Http::ParameterFilter
      .new(Rails.application.config.filter_parameters)
      .filter(attributes)
  end

  def event_from_resource
    return if resource.nil?
    new_resource? ? 'create' : 'update'
  end

  def new_resource?
    resource.instance_variable_get(:@new_record_before_save) ||
      resource.previous_changes['id']&.first.nil? && resource.previous_changes['id']&.second.present?
  end

  def json
    ActiveModelSerializers::SerializableResource
      .new(
        self,
        adapter: :json_api,
        include: :resource,
        key_transform: :camel_lower,
        scope: OpenStruct.new(doorkeeper_scopes: %w(service))
      )
      .to_json
  end

  def parse_json_api(attrs)
    self.resource = json_api_included_resource(attrs, attrs.dig('data', 'relationships', 'resource', 'data'))
    self.resource_id = resource['id']
    self.resource_type = resource['type']
    self.affected_resources = attrs.dig('data', 'relationships', 'affected_resources')&.map do |r|
      json_api_included_resource(attrs, r['data'])
    end
    self.event = parse_event(attrs)
    self.changes = attrs.dig('data', 'attributes', 'changes')&.map(&:with_indifferent_access)
  end

  def parse_event(attrs)
    attrs.dig('data', 'type').split('Event').first
  end

  def parse_resource(attrs)
    self.resource = attrs
    self.resource_id = resource.try(:context_id) || resource.id
    self.resource_type = resource.class.name.pluralize.camelize(:lower)
    self.event = event_from_resource
    self.changes = changes_from_resource
  end
end
