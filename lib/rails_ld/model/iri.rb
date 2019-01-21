# frozen_string_literal: true

module RailsLD
  module Model
    module Iri
      extend ActiveSupport::Concern

      include UriTemplateHelper

      # The canonical IRI of the object. The used URL may differ.
      # @return [RDF::URI] IRI of the object.
      def canonical_iri(opts = {})
        RDF::URI(path_with_hostname(canonical_iri_path(opts)))
      end

      def canonical_iri_opts
        {id: id, :"#{self.class.name.underscore}_id" => id}
      end

      # @return [String]
      def canonical_iri_path(opts = {})
        return iri_path(opts) if canonical_iri_template_name.nil?
        expand_uri_template(canonical_iri_template_name, **canonical_iri_opts.merge(opts))
      end

      def canonical_iri_template_name
        name = "#{model_name.route_key}_canonical_iri"
        name if uri_template(name).present?
      end

      # The IRI of the object. The used URL may differ.
      # @return [RDF::URI] IRI of the object.
      def iri(opts = {})
        return @iri if @iri && opts.blank?
        iri = RDF::DynamicURI(path_with_hostname(iri_path(opts)))
        @iri = iri if opts.blank?
        iri
      end

      def iri_cachable?
        respond_to?(:has_attribute?) && has_attribute?(:iri_cache)
      end

      def iri_path_from_cache(opts = {})
        return if opts.present? || !persisted? || !iri_cachable?
        iri_cache || cache_iri_path!
      end

      def iri_path_from_template(opts = {})
        expand_uri_template(iri_template_name, **iri_opts.merge(opts))
      end

      def iri_opts
        {id: to_param, :"#{self.class.name.underscore}_id" => to_param}
      end

      # @return [String]
      def iri_path(opts = {})
        iri_path_from_cache(opts) || iri_path_from_template(opts)
      end

      def iri_template_name
        "#{model_name.route_key}_iri"
      end

      # rubocop:disable Rails/SkipsModelValidations
      def cache_iri_path!
        @iri = nil
        return unless iri_cachable? && persisted?
        update_column(:iri_cache, iri_path_from_template)
        iri_path_from_template
      end
      # rubocop:enable Rails/SkipsModelValidations

      def reload(_opts = {})
        @iri = nil
        super
      end

      module ClassMethods
        def iri
          NS::ARGU[name.demodulize]
        end
      end
    end
  end
end
