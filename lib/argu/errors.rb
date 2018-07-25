# frozen_string_literal: true

require 'argu/errors/forbidden'
require 'argu/errors/unauthorized'

module Argu
  module Errors
    TYPES = YAML.safe_load(File.read(Rails.root.join('config', 'errors.yml'))).with_indifferent_access.freeze
  end
end
