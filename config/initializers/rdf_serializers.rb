# frozen_string_literal: true

require 'rdf/serializers/renderers'

RDF::Serializers.configure do |config|
  config.always_include_named_graphs = false
  config.default_graph = NS::LL[:supplant]
end

opts = {
  prefixes: Hash[NS.constants.map { |const| [const.to_s.downcase.to_sym, NS.const_get(const)] }]
}

RDF_CONTENT_TYPES = %i[n3 nt nq ttl jsonld rdf hndjson].freeze

# Only content-types which are rendered with the rdf adapter
RDF::Serializers::Renderers.register(%i[n3 ntriples nquads turtle jsonld rdf], opts)

RDF::Serializers::Renderers.add_renderer(:hndjson, 'application/hex+x-ndjson', :hndjson, opts)
