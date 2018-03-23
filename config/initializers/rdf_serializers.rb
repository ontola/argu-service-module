# frozen_string_literal: true

require 'rdf/serializers/renderers'

opts = {
  prefixes: Hash[NS.constants.map { |const| [const.to_s.downcase.to_sym, NS.const_get(const)] }]
}

RDF_CONTENT_TYPES = %i[n3 nt nq ttl jsonld rdf].freeze

RDF::Serializers::Renderers.register(%i[n3 ntriples nquads turtle jsonld rdf], opts)
