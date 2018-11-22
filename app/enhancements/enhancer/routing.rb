# frozen_string_literal: true

module Enhancer
  module Routing
    class << self
      def enhance(klass, enhancement)
        klass.class_attribute(:route_concerns) unless klass.method_defined?(:route_concerns)
        enhancement.try(:dependent_classes)
        klass.route_concerns ||= []
        klass.route_concerns << enhancement.to_s.deconstantize.underscore.to_sym
      end
    end
  end
end
