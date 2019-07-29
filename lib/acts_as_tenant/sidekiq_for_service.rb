# frozen_string_literal: true

# Based on acts_as_tenant/sidekiq

module ActsAsTenant
  module Sidekiq
    class Client
      def call(_worker_class, msg, _queue, _redis_pool)
        msg['acts_as_tenant'] ||= ActsAsTenant.current_tenant.attributes if ActsAsTenant.current_tenant.present?

        yield
      end
    end

    class Server
      def call(_worker_class, msg, _queue)
        if msg.key?('acts_as_tenant')
          tenant = Page.new(msg['acts_as_tenant'])

          ActsAsTenant.with_tenant(tenant) do
            yield
          end
        else
          yield
        end
      end
    end
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add ActsAsTenant::Sidekiq::Client
  end
end

Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add ActsAsTenant::Sidekiq::Client
  end
  config.server_middleware do |chain|
    if defined?(Sidekiq::Middleware::Server::RetryJobs)
      chain.insert_before Sidekiq::Middleware::Server::RetryJobs, ActsAsTenant::Sidekiq::Server
    else
      chain.add ActsAsTenant::Sidekiq::Server
    end
  end
end
