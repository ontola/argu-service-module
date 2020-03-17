# frozen_string_literal: true

module Rails
  module ConsoleMethods
    extend ActiveSupport::Concern

    included do
      current = ''
      available = %w[public] + Apartment.tenant_names
      available_str = available.map.with_index { |tenant, index| "#{index}: #{tenant}" }.join(', ')

      until available.include?(current)
        Rails.logger.info(
          ActiveSupport::LogSubscriber.new.send(:color, "Set Apartment tenant: (#{available_str})", :yellow)
        )
        current = STDIN.gets.chomp
        current = available[current.to_i] if current.scan(/\D/).empty?
      end

      Apartment::Tenant.switch! current
      Rails.logger.info(
        ActiveSupport::LogSubscriber.new.send(:color, "Switched to #{Apartment::Tenant.current}", :yellow)
      )
    end
  end
end
