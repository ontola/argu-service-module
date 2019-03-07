# frozen_string_literal: true

module Enhancer
  module Routing
    class << self
      def enhance(klass, enhancement)
        enhancement.try(:dependent_classes)
        initialize_route_concerns(klass)
        klass.route_concerns << enhancement.to_s.deconstantize.underscore.to_sym
      end

      private

      def initialize_route_concerns(klass)
        return if klass.route_concerns && klass.method(:route_concerns).owner == klass.singleton_class

        klass.route_concerns = klass.superclass.try(:route_concerns)&.dup || []
      end
    end
  end
end
