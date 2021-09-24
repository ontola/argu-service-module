# frozen_string_literal: true

module ServiceHelper
  CLUSTER_DOMAIN = ENV['CLUSTER_DOMAIN'] || 'cluster.local'
  DEFAULT_SERVICE_PORT = ENV['DEFAULT_SERVICE_PORT'] || '3000'
  DEFAULT_SERVICE_PROTO = ENV['DEFAULT_SERVICE_PROTO'] || 'http'
  NAMESPACE = ENV['NAMESPACE'] || ''
  SVC_DNS_PREFIX = ENV['SERVICE_DNS_PREFIX'] || 'svc'
  CLUSTER_URL_BASE =
    ENV['CLUSTER_URL_BASE'] || [NAMESPACE.presence, SVC_DNS_PREFIX.presence, CLUSTER_DOMAIN.presence].compact.join('.')

  def expand_service_url(service, path, **params)
    url = URI(service_url(service))
    url.path = path
    url.fragment = params.delete(:fragment)
    url.query = params.to_param if params.present?
    url.to_s
  end

  def service(service_name, token: user_token)
    OAuth2::AccessToken.new(service_client(service_name), token)
  end

  def service_url(service)
    ENV["#{service.upcase}_URL"] ||
      "#{DEFAULT_SERVICE_PROTO}://#{service}.#{[CLUSTER_URL_BASE, DEFAULT_SERVICE_PORT].compact.join(':')}"
  end

  private

  def service_client(service_name)
    OAuth2::Client.new(ENV['ARGU_APP_ID'], ENV['ARGU_APP_SECRET'], site: service_url(service_name))
  end
end
