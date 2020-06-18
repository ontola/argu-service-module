# frozen_string_literal: true

module Argu
  class Cache
    include DeltaHelper

    def write(delta)
      Argu::Redis.publish(ENV['CACHE_CHANNEL'], hex_delta(delta))
    end

    def scope
      @scope ||= UserContext.new(user: GuestUser.new, doorkeeper_scopes: %w[guest])
    end
  end
end
