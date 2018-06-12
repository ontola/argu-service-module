# frozen_string_literal: true

module ChildHelper
  # Can be overridden in other services
  def child_instance(_parent, klass)
    klass.new
  end
end
