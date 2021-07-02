# frozen_string_literal: true

class ResourceInvalidationStreamWorker
  include Sidekiq::Worker

  def perform(type, iri, resource_type)
    return if Rails.env.test?

    redis = Redis.new(db: Rails.configuration.stream_redis_database)

    entry = {
      type: type,
      resource: iri,
      resourceType: resource_type
    }
    id = redis.xadd(Rails.configuration.cache_stream, entry)

    raise('No message id returned, implies failure') if id.blank?
  end
end
