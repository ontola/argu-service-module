# frozen_string_literal: true

require 'rdf/serializers/renderers'

RDF::Serializers.configure do |config|
  config.always_include_named_graphs = false
end

opts = {
  prefixes: Hash[NS.constants.map { |const| [const.to_s.downcase.to_sym, NS.const_get(const)] }]
}

RDF_CONTENT_TYPES = %i[n3 nt nq ttl jsonld rdf].freeze

RDF::Serializers::Renderers.register(%i[n3 ntriples nquads turtle jsonld rdf], opts)
