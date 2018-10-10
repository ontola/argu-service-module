# frozen_string_literal: true

module RailsLD
  module Helpers
    module OntolaActions
      def add_exec_action_header(headers, action)
        headers['Exec-Action'] ||= ''
        headers['Exec-Action'] += "#{action}\n"
      end

      def ontola_copy_action(value)
        NS::ONTOLA["actions/copyToClipboard?#{{value: value}.to_param}"]
      end

      def ontola_redirect_action(location)
        location =
          location
            .gsub("https://#{Rails.application.config.host_name}", "https://app.#{Rails.application.config.host_name}")
        NS::ONTOLA["actions/redirect?#{{location: location}.to_param}"]
      end

      def ontola_snackbar_action(text)
        NS::ONTOLA["actions/snackbar?#{{text: text}.to_param}"]
      end
    end
  end
end
