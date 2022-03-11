# frozen_string_literal: true

RDF::Serializers.configure do |config|
  config.always_include_named_graphs = false
  config.default_graph = NS.ld[:supplant]
end
