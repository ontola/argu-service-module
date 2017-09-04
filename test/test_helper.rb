# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rails/test_help'

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema! if defined?(ActiveRecord)

require 'factory_girl_rails'
require 'minitest/spec'
require 'assert_difference'
require 'webmock/minitest'
require 'argu/test_helpers'
require 'argu/test_mocks'

module ActiveSupport
  class TestCase
    include FactoryGirl::Syntax::Methods
    include AssertDifference, TestMocks, Argu::TestHelpers::RequestHelpers
    extend MiniTest::Spec::DSL
  end
end
