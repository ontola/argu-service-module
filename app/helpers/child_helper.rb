# frozen_string_literal: true

module ChildHelper
  def child_instance(parent, klass)
    parent.build_child(klass)
  end
end
