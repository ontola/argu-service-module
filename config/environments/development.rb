# frozen_string_literal: true

require 'argu/service'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  BetterErrors::Middleware.allow_ip! ENV['TRUSTED_IP'] if ENV['TRUSTED_IP']
  config.web_console.whitelisted_ips = ['192.168.0.0/16', '10.0.1.0/16', '172.17.0.0/16', ENV['TRUSTED_IP']]
  config.hosts << config.host_name
  config.hosts << ".#{Argu::Service::CLUSTER_URL_BASE}"
  config.hosts << '.localdev'
  config.hosts << '.localtest'

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = true
  config.allow_concurrency = true

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {'Cache-Control' => 'public, max-age=172800'}
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = false
  config.ssl_options = {
    hsts: {expires: 0, subdomains: true}, redirect: {exclude: ->(request) { request.path =~ %r{/d/health$} }}
  }

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.try(:active_record)&.migration_error = :page_load

  config.debug_exception_response_format = :default
  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end
