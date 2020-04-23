# frozen_string_literal: true

class DataEventSerializer
  include RDF::Serializers::ObjectSerializer
  include LinkedRails::Serializer

  attributes :changes

  has_one :resource, polymorphic: true

  # Hack to dynamically set the type of the event.
  # When we stop using json_api for broadcasting events this is no longer needed.
  def hash_for_one_record
    hash = super
    hash[:data][:type] = "#{@resource.event}Event"
    hash
  end
end
