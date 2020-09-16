# frozen_string_literal: true

module Argu
  module WhitelistConstraint
    module_function

    WHITELIST = ENV['INT_IP_WHITELIST']&.split(',')&.map { |ip| IPAddr.new(ip) } || []

    def matches?(request)
      ip = request_ip(request.ip)
      remote_ip = request_ip(request.remote_ip)

      Bugsnag.notify("#{request.ip} is not present") unless ip

      allowed = [ip, remote_ip].all? do |req_ip|
        WHITELIST.any? { |allowed_ip| allowed_ip.include?(req_ip) }
      end
      log_verdict(allowed, request, ip, remote_ip)
      allowed
    end

    def log_verdict(allowed, request, ip, remote_ip)
      return if Rails.env.production?

      verdict = allowed ? 'pass' : 'fail'
      Rails.logger.debug("[WhitelistConstraint] #{verdict} for #{request.url} by ip: #{ip}, remote ip: #{remote_ip}")
    end

    def request_ip(ip)
      return nil unless ip.is_a?(String) && ip.present?

      IPAddr.new(ip)
    end
  end
end
