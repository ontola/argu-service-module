# frozen_string_literal: true

module Enhancer
  module Controller
    class << self
      def enhance(klass, enhancement)
        klass.controller_class!.include enhancement
      end
    end

    module Enhanceable
      extend ActiveSupport::Concern

      module ClassMethods
        def controller_class!
          controller_class || define_controller_class
        end

        private

        def controller_class
          "#{name.pluralize}Controller".safe_constantize
        end

        def controller_superclass
          "#{superclass.name.pluralize}Controller".safe_constantize || ApplicationController
        end

        def define_controller_class
          namespace_class.const_set("#{name.demodulize.pluralize}Controller", Class.new(controller_superclass))
        end
      end
    end
  end
end
