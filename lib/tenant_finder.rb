# frozen_string_literal: true

class TenantFinder
  class << self
    def from_url(url)
      uri = URI(url)
      new(uri.host, uri.port, uri.path).tenant
    end

    def from_request(request)
      new(request.host, request.port, request.path).tenant
    end
  end

  def initialize(host, port, path)
    @host = host
    @port = port
    @path = path
  end

  def tenant
    api.get_tenant("#{@host}#{@path}") if @host.include?('.')
  end

  private

  def api
    @api ||= Argu::API.new
  end
end
