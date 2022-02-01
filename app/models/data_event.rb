# frozen_string_literal: true

class DataEvent
  extend JsonAPIHelper
  include SerializationHelper
  include ActiveModel::Model
  include LinkedRails::Model
  attr_accessor :affected_resources, :changes, :event, :resource, :resource_id, :resource_type

  def as_json(_opts = {})
    serializable_resource(
      self,
      %w[service],
      include: event == 'destroy' ? nil : [:resource]
    ).as_json
  end

  def id
    nil
  end

  def publish
    Connection.publish('events', to_json)
  end

  class << self
    # Creates a new data event from JSON
    # Used for parsing incoming data events
    # @return [DataEvent]
    def parse(body)
      attrs = JSON.parse(body)
      data_resource = attrs.dig('data', 'relationships', 'resource', 'data')

      new(
        resource_id: data_resource['id'],
        resource_type: data_resource['type'],
        resource: json_api_included_resource(attrs, id: data_resource['id'], type: data_resource['type']),
        affected_resources: parse_affected_resources(attrs),
        event: parse_event(attrs),
        changes: attrs.dig('data', 'attributes', 'changes')&.map(&:with_indifferent_access)
      )
    end

    # Schedules a resource to be broadcasted as data event
    # @return [Hash] The attributes to be assigned to the data event
    def publish(resource)
      attrs = attributes_from_resource(resource)
      BroadcastWorker.perform_async(attrs.as_json)
      attrs
    end

    private

    def attributes_from_resource(resource)
      event = event_from_resource(resource)

      {
        resource_id: resource.id,
        resource_type: type_from_resource(resource),
        event: event,
        changes: event == 'update' ? serialize_changes(resource) : nil
      }
    end

    def changes_from_resource(resource)
      resource.try(:broadcastable_changes) || resource.previous_changes
    end

    def event_from_resource(resource)
      return if resource.nil?

      if new_resource?(resource)
        'create'
      elsif resource.destroyed?
        'destroy'
      else
        'update'
      end
    end

    def filtered_attributes(attributes)
      ActiveSupport::ParameterFilter
        .new(Rails.application.config.filter_parameters)
        .filter(attributes)
    end

    def new_resource?(resource)
      resource.instance_variable_get(:@new_record_before_save) ||
        changes_from_resource(resource)['id']&.first.nil? && changes_from_resource(resource)['id']&.second.present?
    end

    def parse_affected_resources(attrs)
      attrs.dig('data', 'relationships', 'affected_resources')&.map do |r|
        json_api_included_resource(attrs, r['data'])
      end
    end

    def parse_event(attrs)
      attrs.dig('data', 'type').split('Event').first
    end

    def serialize_changes(resource)
      iri = resource.try(:iri)

      [
        {
          id: iri || resource.id,
          type: type_from_resource(resource),
          attributes: filtered_attributes(changes_from_resource(resource))
        }
      ]
    end

    def type_from_resource(resource)
      resource.class.name.singularize.underscore
    end
  end
end
