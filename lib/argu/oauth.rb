# frozen_string_literal: true

module Argu
  class OAuth
    include JWTHelper

    REDIS_CLIENT_KEY = "#{Rails.application.config.service_name}:client"

    def client(service_url)
      @client ||= OAuth2::Client.new(
        client_data[:id],
        client_data[:secret],
        site: service_url,
        token_url: client_data[:token_endpoint]
      )
    end

    def service_token
      return client_data[:token] if valid_token?(client_data[:token])

      client_data[:token] = request_new_token
      Argu::Redis.set(REDIS_CLIENT_KEY, client_data.to_json)
      client_data[:token]
    end

    private

    def client_data
      self.class.client_data
    end

    def request_new_token(retrying: false)
      Argu::Service.new(:data).oauth_client.client_credentials.get_token(scope: 'service').token
    rescue OAuth2::Error => e
      raise(e) if retrying || e.code != 'invalid_client'

      self.class.clear_client_data
      request_new_token(retrying: true)
    end

    def valid_token?(token)
      return false if token.blank?

      decode_token(token)
    rescue JWT::ExpiredSignature
      false
    end

    class << self
      def clear_client_data
        Argu::Redis.delete(REDIS_CLIENT_KEY)
        @client_data = nil
      end

      def client(service_url)
        new.client(service_url)
      end

      def client_data
        @client_data ||= JSON.parse(
          Argu::Redis.cached_lookup(REDIS_CLIENT_KEY) do
            client = register_client
            {
              id: client.identifier,
              secret: client.secret,
              token_endpoint: URI(openid_config.token_endpoint).path
            }.to_json
          end
        ).with_indifferent_access
      end

      def service_token
        new.service_token
      end

      private

      def openid_config
        @openid_config ||= OpenIDConnect::Discovery::Provider::Config.discover!(Rails.application.config.origin)
      end

      def register_client
        OpenIDConnect::Client::Registrar.new(
          openid_config.registration_endpoint,
          client_name: Rails.application.config.service_name,
          application_type: 'web',
          redirect_uris: ['https://example.com'],
          scopes: %w[user service],
          subject_type: 'public'
        ).register!
      end
    end
  end
end
