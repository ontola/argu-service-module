# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema! if defined?(ActiveRecord)

require 'factory_girl_rails'
require 'assert_difference'
require 'webmock/rspec'
require 'argu/test_helpers'
require 'argu/test_mocks'
require 'fakeredis/rspec'
require 'support/iri_helpers'
require 'sidekiq/testing'

Sidekiq::Testing.server_middleware do |chain|
  chain.add ActsAsTenant::Sidekiq::Server
end

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.include AssertDifference
  config.include Argu::TestHelpers::RequestHelpers
  config.include Argu::TestHelpers::TestAssertions
  config.include Argu::TestMocks
  config.include IriHelpers
  config.include JWTHelper

  config.before(:each, type: :request) do
    host! ENV['HOSTNAME']

    Argu::Redis.set(Argu::OAuth::REDIS_CLIENT_KEY, {token: sign_payload({scopes: %w[service]})}.to_json)
  end

  config.before do
    find_tenant_mock
  end

  config.after do
    mail_workers = Sidekiq::Worker.jobs.select { |j| j['class'] == 'SendEmailWorker' }
    Sidekiq::Worker.clear_all

    assert_equal(
      0,
      mail_workers.count,
      "Found #{mail_workers.count} unexpected mail(s): #{mail_workers.map { |opts| opts['args'].first }}"
    )
  end

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end

def service_headers(accept: nil, bearer: @bearer_token)
  headers = {}
  if accept
    headers['Accept'] = accept.is_a?(Symbol) ? Mime::Type.lookup_by_extension(accept).to_s : accept
  end
  headers['Authorization'] = "Bearer #{bearer}" if bearer
  headers
end
