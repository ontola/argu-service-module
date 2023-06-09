# frozen_string_literal: true

module ActiveResource
  class Base
    include LinkedRails::Model

    def root_relative_iri
      @root_relative_iri ||= RDF::URI(iri.to_s.split(ActsAsTenant.current_tenant.iri).last) if respond_to?(:iri)
    end

    def uuid
      return attributes[:uuid] unless respond_to?(:canonical_iri) && canonical_iri&.to_s&.include?('/edges/')

      @uuid ||= canonical_iri.split('/edges/').last
    end
  end
end
