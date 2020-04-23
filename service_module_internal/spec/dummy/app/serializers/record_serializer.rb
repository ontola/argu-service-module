# frozen_string_literal: true

class RecordSerializer
  include RDF::Serializers::ObjectSerializer
  attributes :attr1, :attr2
end
