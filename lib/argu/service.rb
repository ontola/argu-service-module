# frozen_string_literal: true

module Argu
  class Service
    CLUSTER_DOMAIN = ENV['CLUSTER_DOMAIN'] || 'cluster.local'
    DEFAULT_SERVICE_PORT = ENV['DEFAULT_SERVICE_PORT'] || '3000'
    DEFAULT_SERVICE_PROTO = ENV['DEFAULT_SERVICE_PROTO'] || 'http'
    NAMESPACE = ENV['NAMESPACE'] || ''
    SVC_DNS_PREFIX = ENV['SERVICE_DNS_PREFIX'] || 'svc'
    CLUSTER_URL_BASE = ENV['CLUSTER_URL_BASE'] ||
      [NAMESPACE.presence, SVC_DNS_PREFIX.presence, CLUSTER_DOMAIN.presence].compact.join('.')

    attr_accessor :service_name

    def initialize(service_name)
      self.service_name = service_name
    end

    def client(token = nil)
      OAuth2::AccessToken.new(oauth_client, token)
    end

    def expand_url(path, **params)
      url = URI(service_url)
      url.path = path
      url.fragment = params.delete(:fragment)
      url.query = params.to_param if params.present?
      url.to_s
    end

    def oauth_client
      @oauth_client ||= Argu::OAuth.client(service_url)
    end

    private

    def service_url
      port = ENV["#{service_name.upcase}_SERVICE_PORT"] || DEFAULT_SERVICE_PORT

      ENV["#{service_name.upcase}_URL"] ||
        "#{DEFAULT_SERVICE_PROTO}://#{service_name}.#{[CLUSTER_URL_BASE, port].compact.join(':')}"
    end
  end
end
