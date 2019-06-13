# frozen_string_literal: true

class BroadcastWorker
  include Sidekiq::Worker

  def perform(attrs = {})
    attrs = attrs.with_indifferent_access
    attrs[:resource] = attrs[:resource_type].classify.constantize.find(attrs[:resource_id])
    attrs[:resource_id] = attrs[:resource].iri if attrs[:resource].respond_to?(:iri)

    DataEvent.new(attrs).publish
  end
end
