# frozen_string_literal: true

module Concernable
  extend ActiveSupport::Concern

  included do
    class_attribute :concerns
    self.concerns ||= []

    def actions_class
      self.class.actions_class!
    end
  end

  module ClassMethods
    def actions_class!
      actions_class || define_actions_class || raise("could not find #{name}Actions")
    end

    def actions_class
      "::Actions::#{name}Actions".safe_constantize
    end

    def action_superclass
      "::Actions::#{superclass.name}Actions".safe_constantize
    end

    # Adds concerns to a model and initializers their dependent modules.
    # Note: Should only be used for concerns which have the full API (c::Actions, c::Serializer)
    def concern(c)
      self.concerns ||= []
      self.concerns += [c]
      include c
      actions_class!.include c::Actions
      serialization_class!.include c::Serializer
    end

    def define_actions_class
      return if action_superclass.nil?
      ::Actions.const_set("#{name}Actions", Class.new(action_superclass))
    end

    def serialization_class!
      serialization_class || define_serialization_class || raise("could not find #{name}Serializer")
    end

    def serialization_class
      "#{name}Serializer".safe_constantize
    end

    def serialization_superclass
      "#{superclass.name}Serializer".safe_constantize
    end

    def define_serialization_class
      return if serialization_superclass.nil?
      ::Actions.const_set("#{name}Serializer", Class.new(serialization_superclass))
    end
  end

  module Actions; end

  module Serializer; end
end
