# frozen_string_literal: true

module ChildHelper
  module_function

  def child_instance(_parent, klass, opts = {})
    klass.new(klass.send(:attributes_for_new, opts))
  end
end
