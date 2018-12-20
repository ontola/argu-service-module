# frozen_string_literal: true

module RDF
  class Sequence
    attr_accessor :members, :node
    alias read_attribute_for_serialization send

    def initialize(members, id: nil)
      self.node = id || RDF::Node.new
      self.members = members
    end
  end
end
