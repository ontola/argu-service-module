# frozen_string_literal: true

module Enhancer
  module Policy
    class << self
      def enhance(klass, enhancement)
        Pundit::PolicyFinder.new(klass).policy.include enhancement
      end
    end
  end
end
