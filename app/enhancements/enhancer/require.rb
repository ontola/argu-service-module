# frozen_string_literal: true

module Enhancer
  module Require
    class << self
      def enhance(klass, enhancement)
        enhancement.requirements.each { |requirement| klass.enhance requirement }
      end
    end
  end
end
