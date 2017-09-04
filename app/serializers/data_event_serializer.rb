# frozen_string_literal: true

class DataEventSerializer < ActiveModel::Serializer
  def self.type(type = nil, &block)
    self._type = block || type
  end
  type { |object| "#{object.event}Event" }

  attributes :changes

  has_one :resource
end
