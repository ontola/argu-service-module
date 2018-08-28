# frozen_string_literal: true

module RDF
  module Util
    module Logger
      def log_and_report_error(*args)
        log_without_reporting_error(*args)
        Bugsnag.notify(args.first)
      end

      # rubocop:disable Style/Alias
      alias_method :log_without_reporting_error, :log_error
      alias_method :log_error, :log_and_report_error
      # rubocop:enable Style/Alias
    end
  end
end
