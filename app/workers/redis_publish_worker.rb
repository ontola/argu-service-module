# frozen_string_literal: true

class RedisPublishWorker
  include Sidekiq::Worker

  def perform(channel, body, required_listeners = 0)
    listeners = Argu::Redis.publish(channel, body)

    return if Rails.env.test? || listeners >= required_listeners

    raise("Expected #{required_listeners} listener, but only had #{listeners}")
  end
end
