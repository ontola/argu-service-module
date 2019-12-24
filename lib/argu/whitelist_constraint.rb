# frozen_string_literal: true

module Argu
  module WhitelistConstraint
    module_function

    WHITELIST = ENV['INT_IP_WHITELIST']&.split(',')&.map { |ip| IPAddr.new(ip) } || []

    def matches?(request)
      ip = request_ip(request.ip)
      remote_ip = request_ip(request.remote_ip)
      [ip, remote_ip].all? do |req_ip|
        WHITELIST.any? { |allowed_ip| allowed_ip.include?(req_ip) }
      end
    end

    def request_ip(ip)
      Bugsnag.notify("#{ip} is not a string but a #{ip.class}") unless ip.is_a?(String)

      IPAddr.new(ip)
    end
  end
end
