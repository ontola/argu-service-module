# frozen_string_literal: true

class EntryPointSerializer < BaseSerializer
  attribute :label, predicate: NS::SCHEMA[:name]
  attribute :url, predicate: NS::SCHEMA[:url]
  attribute :url_template, predicate: NS::SCHEMA[:urlTemplate]
  attribute :http_method, key: :method, predicate: NS::SCHEMA[:method]

  has_one :image, predicate: NS::SCHEMA[:image]

  def image
    serialize_image(object.image)
  end

  def type
    NS::SCHEMA[:EntryPoint]
  end
end
