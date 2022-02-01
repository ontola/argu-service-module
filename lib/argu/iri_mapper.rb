# frozen_string_literal: true

module Argu
  class IRIMapper < LinkedRails::IRIMapper
    class << self
      def opts_from_iri(iri, method: 'GET')
        query = Rack::Utils.parse_nested_query(URI(iri.to_s).query)
        params = Rails.application.routes.recognize_path(sanitized_path(RDF::URI(iri.to_s)), method: method)

        route_params_to_opts(params.merge(query), iri.to_s)
      rescue ActionController::RoutingError
        EMPTY_IRI_OPTS.dup
      end

      private

      def sanitized_path(iri) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
        iri.path = "#{iri.path}/" unless iri.path.ends_with?('/')
        tenant_path = ActsAsTenant.current_tenant&.iri&.path
        uri = tenant_path.present? ? iri.to_s.split("#{ActsAsTenant.current_tenant.iri.path}/").last : iri
        path = URI(uri).path
        iri_suffix = Rails.application.config.try(:iri_suffix)
        return path if iri_suffix.blank? || path.start_with?(iri_suffix) || path.start_with?("/#{iri_suffix}")

        [iri_suffix, path.delete_prefix('/')].join('/')
      end
    end
  end
end
