# frozen_string_literal: true

require 'argu/cache'

class BroadcastWorker
  include Sidekiq::Worker

  attr_accessor :data_event

  def perform(attrs = {})
    attrs = attrs.with_indifferent_access
    attrs[:resource] = attrs[:resource_type].classify.constantize.find(attrs[:resource_id])
    attrs[:resource_id] = attrs[:resource].iri if attrs[:resource].respond_to?(:iri)

    self.data_event = data_event_from_attrs(attrs)

    write_to_cache
    publish_data_event
  end

  def resource=(resource)
    self.data_event = data_event_from_attrs(resource: resource)
  end

  def write_to_cache
    resource.try(:write_to_cache, Argu::Cache.new)
  end

  private

  def data_event_from_attrs(attrs)
    DataEvent.new(attrs)
  end

  def publish_data_event
    data_event.publish
  end

  def resource
    data_event.resource
  end
end
