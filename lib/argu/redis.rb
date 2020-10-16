# frozen_string_literal: true

# Our own wrapper for redis, to make stuff like error handling and host initialisation easier.
module Argu
  class Redis
    # Argu configured redis instance, use this by default.
    def self.redis_instance(opts = {})
      opts[:url] ||= ENV['REDIS_URL']

      ::Redis.new(opts)
    end

    def self.exists(key, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].exists(key)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
    end

    def self.expire(key, seconds, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].expire(key, seconds)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
    end

    def self.delete(key, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].del(key)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
    end

    def self.delete_all(keys, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].del(*keys) if keys.present?
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
    end

    def self.get(key, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].get(key)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
    end

    def self.keys(pattern = '*', opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].keys(pattern)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
      []
    end

    def self.persist(key, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].persist(key)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
    end

    def self.rename(old_key, new_key, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].rename(old_key, new_key)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
    end

    def self.set(key, value, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].set(key, value)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
    end

    def self.setex(key, timeout, value, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].setex(key, timeout, value)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
    end

    def self.hgetall(key, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].hgetall(key)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
      {}
    end

    def self.hmset(key, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].hmset(key, *opts[:values])
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
    end

    def self.lpush(key, value, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].lpush(key, value)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
    end

    def self.lrange(key, start, stop, opts = {})
      opts[:redis] ||= redis_instance(opts[:redis_opts] || {})

      opts[:redis].lrange(key, start, stop)
    rescue ::Redis::CannotConnectError => e
      rescue_redis_connection_error(e)
      []
    end

    # Delegate `::Redis::CannotConnectError` to this method.
    # It automatically logs and sends to bugsnag.
    def self.rescue_redis_connection_error(error)
      Rails.logger.error 'Redis not available'
      ::Bugsnag.notify(error) do |report|
        report.severity = 'error'
      end
      nil
    end
  end
end
