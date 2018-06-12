# frozen_string_literal: true

class EntryPointSerializer < BaseSerializer
  attribute :label, predicate: NS::SCHEMA[:name]
  attribute :url, predicate: NS::SCHEMA[:url]
  attribute :http_method, key: :method, predicate: NS::SCHEMA[:httpMethod]

  has_one :action_body, predicate: NS::LL[:actionBody]
  has_one :image, predicate: NS::SCHEMA[:image]

  def image
    serialize_image(object.image)
  end

  def type
    NS::SCHEMA[:EntryPoint]
  end

  def http_method
    object.http_method.upcase
  end
end
