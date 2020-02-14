# frozen_string_literal: true

module Enhanceable
  extend ActiveSupport::Concern

  included do
    class_attribute :enhancements, :route_concerns

    const_defined?(:Enhancer) && Enhancer.constants.each do |constant|
      if Enhancer.const_get(constant).const_defined?(:Enhanceable, false)
        include Enhancer.const_get(constant).const_get(:Enhanceable)
      end
    end
  end

  def enhanced_with?(enhancement)
    self.class.enhancements.include?(enhancement)
  end

  module ClassMethods
    # Adds enhancements to a model and initializers their dependent modules.
    def enhance(enhancement, only: [], except: [])
      self.enhancements ||= superclass.try(:enhancements)&.dup || []
      return if enhancements.include?(enhancement)

      self.enhancements += [enhancement]
      execute_enhancers(enhancement, enhancers_for(enhancement, only, except))
    end

    def enhancers_for(enhancement, only, except)
      enhancers = enhancement.constants
      enhancers &= only if only.present?
      enhancers -= except if except.present?
      enhancers -= [:ActiveRecordExtension]
      enhancers
    end

    def execute_enhancers(enhancement, enhancers)
      enhancers.each do |enhancer|
        Enhancer.const_get(enhancer).enhance(self, enhancement.const_get(enhancer))
      end
    end

    def enhanced_with?(enhancement)
      self.enhancements.include?(enhancement)
    end

    def namespace_class
      @namespace_class ||= name.deconstantize.presence&.constantize || Kernel
    end
  end
end
