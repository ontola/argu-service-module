# frozen_string_literal: true

class EntryPointSerializer < BaseSerializer
  attribute :label, predicate: NS::SCHEMA[:name]
  attribute :url, predicate: NS::SCHEMA[:url]
  attribute :url_template, predicate: NS::SCHEMA[:urlTemplate]
  attribute :http_method, key: :method, predicate: NS::SCHEMA[:method]

  has_one :image, predicate: NS::SCHEMA[:image] do
    obj = object.image
    if obj
      if defined?(MediaObject) && obj.is_a?(MediaObject)
        obj
      elsif obj.is_a?(String)
        obj = obj.gsub(/^fa-/, 'http://fontawesome.io/icon/')
        {
          id: obj,
          type: NS::ARGU[:FontAwesomeIcon]
        }
      end
    end
  end

  def type
    NS::SCHEMA[:EntryPoint]
  end
end
