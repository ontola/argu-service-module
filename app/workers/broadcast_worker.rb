# frozen_string_literal: true

class BroadcastWorker
  include Sidekiq::Worker

  attr_accessor :cache, :data_event

  def perform(attrs = {})
    attrs = attrs.with_indifferent_access
    attrs[:resource] = resource_from_attrs(attrs)
    return if attrs[:resource].blank?

    attrs[:resource_id] = attrs[:resource].iri if attrs[:resource].respond_to?(:iri)

    self.data_event = data_event_from_attrs(attrs)

    self.cache = Argu::Cache.new

    invalidate_cache
    publish_data_event
  end

  def resource=(resource)
    self.data_event = data_event_from_attrs(resource: resource)
  end

  def invalidate_cache
    resource.try(:invalidate_cache, @cache)
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

  def resource_from_attrs(attrs)
    attrs[:resource_type].classify.constantize.find_by(id: attrs[:resource_id])
  end
end
