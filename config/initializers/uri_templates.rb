# frozen_string_literal: true

Rails.application.config.uri_templates =
  YAML.safe_load(File.read(Rails.root.join('config/uri_templates.yml')))
    .transform_values { |v| LinkedRails::URITemplate.new("#{v}{#fragment}") }
    .with_indifferent_access.freeze
