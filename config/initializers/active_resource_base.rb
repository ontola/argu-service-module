# frozen_string_literal: true

module ActiveResource
  class Base
    def iri_path
      @iri_path ||= iri.gsub(Rails.application.config.origin, '') if respond_to?(:iri)
    end

    def uuid
      @uuid ||= canonical_iri.split('/edges/').last if respond_to?(:canonical_iri) && canonical_iri&.include?('/edges/')
    end
  end
end
