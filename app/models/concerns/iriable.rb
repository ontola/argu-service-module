# frozen_string_literal: true

module Iriable
  extend ActiveSupport::Concern

  included do
    include UriTemplateHelper

    # The canonical IRI of the object. The used URL may differ.
    # @return [RDF::URI] IRI of the object.
    def canonical_iri
      return iri if uri_template("#{model_name.route_key}_canonical_iri").blank?
      RDF::URI(expand_uri_template("#{model_name.route_key}_canonical_iri", **canonical_iri_opts))
    end

    def canonical_iri_opts
      {id: id, :"#{self.class.name.underscore}_id" => id}
    end

    # The IRI of the object. The used URL may differ.
    # @return [RDF::URI] IRI of the object.
    def iri
      RDF::URI(expand_uri_template("#{model_name.route_key}_iri", **iri_opts))
    end

    def iri_opts
      {id: id, :"#{self.class.name.underscore}_id" => id}
    end

    def self.type_iri
      NS::ARGU[name.demodulize]
    end
  end
end
