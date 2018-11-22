# frozen_string_literal: true

module Enhancer
  module Action
    class << self
      def enhance(klass, enhancement)
        klass.actions_class!.include enhancement
      end
    end

    module Enhanceable
      extend ActiveSupport::Concern

      module ClassMethods
        def actions_class!
          actions_class || define_actions_class
        end

        private

        def actions_class
          "::Actions::#{name}Actions".safe_constantize
        end

        def actions_module
          if parent != Object
            "::Actions::#{parent}".safe_constantize || ::Actions.const_set(parent_name, Module.new)
          else
            ::Actions
          end
        end

        def action_superclass
          "::Actions::#{superclass.name}Actions".safe_constantize || ::Actions::Base
        end

        def define_actions_class
          actions_module.const_set("#{name.demodulize}Actions", Class.new(action_superclass))
        end
      end
    end
  end
end
