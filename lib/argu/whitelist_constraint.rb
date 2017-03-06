# frozen_string_literal: true
module Argu
  module WhitelistConstraint
    module_function

    WHITELIST = ENV['INT_IP_WHITELIST']&.split(',')&.map { |ip| IPAddr.new(ip) } || []

    def matches?(request)
      return true if Rails.env.test?
      [IPAddr.new(request.ip), IPAddr.new(request.remote_ip)].all? do |req_ip|
        WHITELIST.any? { |ip| ip.include?(req_ip) }
      end
    end
  end
end
