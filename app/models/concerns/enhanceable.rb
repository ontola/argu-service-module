# frozen_string_literal: true

module Enhanceable
  extend ActiveSupport::Concern

  included do
    class_attribute :enhancements
    self.enhancements ||= []

    const_defined?(:Enhancer) && Enhancer.constants.each do |constant|
      if Enhancer.const_get(constant).const_defined?(:Enhanceable, false)
        include Enhancer.const_get(constant).const_get(:Enhanceable)
      end
    end
  end

  module ClassMethods
    # Adds enhancements to a model and initializers their dependent modules.
    def enhance(enhancement, only: [])
      self.enhancements ||= []
      return if enhancements.include?(enhancement)
      self.enhancements += [enhancement]
      enhancers = enhancement.constants
      enhancers &= only if only.present?
      enhancers -= [:ActiveRecordExtension]
      enhancers.each do |enhancer|
        Enhancer.const_get(enhancer).enhance(self, enhancement.const_get(enhancer))
      end
    end
  end
end
