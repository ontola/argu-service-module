# frozen_string_literal: false

require_relative 'boot'

require 'bundler'
require 'rails/all'

Bundler.require(*Rails.groups)
require 'linked_rails'

require_relative '../lib/ns'
require_relative '../lib/tenant_middleware'

require 'linked_rails/middleware/linked_data_params'

module Dummy
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.api_only = true
    config.host_name = 'example.com'
    config.origin = "http://#{Rails.application.config.host_name}"
    LinkedRails.host = Rails.application.config.host_name # .force_encoding(Encoding::UTF_8)

    config.oauth_url = ENV['OAUTH_URL']
    config.filter_parameters += [:password]
    config.uri_templates =
      Hash[
        YAML.safe_load(File.read(File.expand_path('../config/uri_templates.yml', __dir__)))
          .map { |k, v| [k, URITemplate.new(v)] }
      ].with_indifferent_access.freeze
    secrets.jwt_encryption_token = 'secret'

    config.middleware.use LinkedRails::Middleware::LinkedDataParams

    config.autoload_paths += %w[lib]
    config.autoload_paths += %W[#{config.root}/app/serializers/base]
    config.autoload_paths += %W[#{config.root}/app/models/actions]
    config.autoload_paths += %W[#{config.root}/app/responders]
    config.autoload_paths += Dir["#{config.root}/app/enhancements/**/"]
  end
end
