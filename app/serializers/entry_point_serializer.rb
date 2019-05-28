# frozen_string_literal: true

class EntryPointSerializer < LinkedRails::EntryPointSerializer
  has_one :serialized_image, predicate: NS::SCHEMA[:image]

  def image; end

  def serialized_image
    serialize_image(object.image)
  end
end
