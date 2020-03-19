# frozen_string_literal: true

module Argu
  class IRIMapper < LinkedRails::IRIMapper
    class << self
      def opts_from_iri(iri, method: 'GET')
        super(sanitized_path(URI(iri)), method: method)
      end

      private

      def sanitized_path(iri) # rubocop:disable Metrics/AbcSize
        iri.path = "#{iri.path}/" unless iri.path.ends_with?('/')
        uri = iri
        if ActsAsTenant.current_tenant.iri.path.present?
          uri = iri.to_s.split("#{ActsAsTenant.current_tenant.iri.path}/").last
        end
        URI(uri).path
      end
    end
  end
end
