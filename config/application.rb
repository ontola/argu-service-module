# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
# require "sprockets/railtie"
require 'rails/test_unit/railtie'

require_relative '../../config/initializers/version'
require_relative '../../config/initializers/build'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative '../lib/ns'
require_relative '../app/serializers/base/base_serializer'

module Service
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.host_name = ENV['HOSTNAME']
    config.oauth_url = ENV['OAUTH_URL']

    config.autoload_paths += %W[#{config.root}/app/models/actions]

    Rails.application.routes.default_url_options[:host] = config.host_name
    ActiveModelSerializers.config.key_transform = :camel_lower
  end
end
