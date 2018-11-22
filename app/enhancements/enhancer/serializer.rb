# frozen_string_literal: true

module Enhancer
  module Serializer
    class << self
      def enhance(klass, enhancement)
        klass.serializer_class!.include enhancement
      end
    end

    module Enhanceable
      extend ActiveSupport::Concern

      module ClassMethods
        def serializer_class!
          serializer_class || define_serializer_class
        end

        private

        def serializer_class
          "#{name}Serializer".safe_constantize
        end

        def serializer_superclass
          "#{superclass.name}Serializer".safe_constantize || BaseSerializer
        end

        def define_serializer_class
          namespace_class.const_set("#{name.demodulize}Serializer", Class.new(serializer_superclass))
        end
      end
    end
  end
end
