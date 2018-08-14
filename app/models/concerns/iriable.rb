# frozen_string_literal: true

module Iriable
  extend ActiveSupport::Concern

  include UriTemplateHelper

  # The canonical IRI of the object. The used URL may differ.
  # @return [RDF::URI] IRI of the object.
  def canonical_iri(opts = {})
    return iri(opts) if uri_template("#{model_name.route_key}_canonical_iri").blank?
    RDF::URI(
      expand_uri_template("#{model_name.route_key}_canonical_iri", **canonical_iri_opts.merge(opts))
    )
  end

  def canonical_iri_opts
    {id: id, :"#{self.class.name.underscore}_id" => id}
  end

  # The IRI of the object. The used URL may differ.
  # @return [RDF::URI] IRI of the object.
  def iri(opts = {})
    iri_from_cache(opts) || iri_from_template(opts)
  end

  def iri_from_cache(opts)
    return if opts.except(:only_path).present? || !persisted? || !has_attribute?(:iri_cache)
    path = iri_cache || cache_iri!
    RDF::URI(opts[:only_path] ? path : path_with_hostname(path))
  end

  def iri_from_template(opts)
    RDF::URI(expand_uri_template(iri_template_name, **iri_opts.merge(opts)))
  end

  def iri_opts
    {id: to_param, :"#{self.class.name.underscore}_id" => to_param}
  end

  # @return [String]
  def iri_path(opts = {})
    iri = iri(opts)
    iri.scheme = nil
    iri.authority = nil
    iri.to_s
  end

  def iri_template_name
    "#{model_name.route_key}_iri"
  end

  def cache_iri!
    return unless has_attribute?(:iri_cache) && persisted?
    update_column(:iri_cache, iri_from_template(only_path: true).to_s)
    iri_from_template(only_path: true)
  end

  module ClassMethods
    def iri
      NS::ARGU[name.demodulize]
    end
  end
end
