# frozen_string_literal: true

module Enhancer
  module Model
    class << self
      def enhance(klass, enhancement)
        klass.include enhancement
      end
    end
  end
end
