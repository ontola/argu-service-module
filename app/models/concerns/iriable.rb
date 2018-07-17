# frozen_string_literal: true

module Iriable
  extend ActiveSupport::Concern

  included do
    include UriTemplateHelper

    # The canonical IRI of the object. The used URL may differ.
    # @return [RDF::URI] IRI of the object.
    def canonical_iri(only_path: false)
      return iri(only_path: only_path) if uri_template("#{model_name.route_key}_canonical_iri").blank?
      RDF::URI(
        expand_uri_template("#{model_name.route_key}_canonical_iri", **canonical_iri_opts.merge(only_path: only_path))
      )
    end

    def canonical_iri_opts
      {id: id, :"#{self.class.name.underscore}_id" => id}
    end

    # The IRI of the object. The used URL may differ.
    # @return [RDF::URI] IRI of the object.
    def iri(opts = {})
      RDF::URI(expand_uri_template("#{model_name.route_key}_iri", **iri_opts.merge(opts)))
    end

    def iri_opts
      {id: id, :"#{self.class.name.underscore}_id" => id}
    end

    # @return [String]
    def iri_path(opts = {})
      iri = iri(opts)
      iri.scheme = nil
      iri.authority = nil
      iri.to_s
    end
  end

  module ClassMethods
    def iri
      NS::ARGU[name.demodulize]
    end
  end
end
