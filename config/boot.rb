# frozen_string_literal: true

ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__.gsub('service_module/', ''))

require 'bundler/setup' # Set up gems listed in the Gemfile.
