# frozen_string_literal: true

module Argu
  module Errors
    ERROR_TYPES = YAML.safe_load(File.read(Rails.root.join('config', 'errors.yml'))).with_indifferent_access.freeze
  end
end
