# frozen_string_literal: true

module Concernable
  extend ActiveSupport::Concern

  included do
    class_attribute :concerns
    self.concerns ||= []
  end

  module ClassMethods
    # Adds concerns to a model and initializers their dependent modules.
    # Note: Should only be used for concerns which have the full API (c::Actions, c::Serializer)
    def concern(c)
      self.concerns ||= []
      self.concerns += [c]
      include c
      actions_class!.include c::Actions
      serializer_class!.include c::Serializer
    end
  end

  module Actions; end

  module Serializer; end
end
