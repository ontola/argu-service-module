# frozen_string_literal: true

Rails.application.config.uri_templates =
  Hash[
    YAML.safe_load(File.read(Rails.root.join('config/uri_templates.yml')))
      .map { |k, v| [k, URITemplate.new("#{v}{#fragment}")] }
  ].with_indifferent_access.freeze
