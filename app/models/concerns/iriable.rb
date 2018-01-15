# frozen_string_literal: true

module Iriable
  extend ActiveSupport::Concern

  included do
    include UriTemplateHelper

    # The (canonical) IRI of the object. The used URL may differ.
    # @return [RDF::URI] IRI of the object.
    def iri
      RDF::URI(expand_uri_template("#{model_name.route_key}_iri", **iri_opts))
    end

    def iri_opts
      {id: id, :"#{self.class.name.underscore}_id" => id}
    end
  end
end
