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
        tenant_path = ActsAsTenant.current_tenant&.iri&.path
        uri = tenant_path.present? ? iri.to_s.split("#{ActsAsTenant.current_tenant.iri.path}/").last : iri
        path = URI(uri).path
        iri_suffix = Rails.application.config.try(:iri_suffix)
        return path if iri_suffix.blank? || path.start_with?(iri_suffix)

        [iri_suffix, path.delete_prefix('/')].join('/')
      end
    end
  end
end
