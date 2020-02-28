# frozen_string_literal: true

module Argu
  class IRIMapper # rubocop:disable Metrics/ClassLength
    extend NestedResourceHelper
    extend RedirectHelper
    extend UriTemplateHelper
    extend UUIDHelper

    class << self
      # Converts an Argu URI into a hash containing the type and id of the resource
      # @return [Hash] The id and type of the resource, or nil if the IRI is not found
      # @example Valid IRI
      #   iri = 'https://argu.co/m/1'
      #   opts_from_iri # => {type: 'motions', id: '1'}
      # @example Invalid IRI
      #   iri = 'https://example.com/m/1'
      #   opts_from_iri # => {}
      # @example Nil IRI
      #   iri = nil
      #   opts_from_iri # => {}
      def opts_from_iri(original_iri, root = nil, method: 'GET')
        iri = URI(original_iri)

        edge_uuid = edge_uuid_from_iri(iri)
        return edge_opts(edge_uuid) if edge_uuid

        root ||= TenantFinder.from_url(iri)
        return {} if root.blank?

        opts = opts_from_route(root, iri, method)
        return {} if opts[:controller].blank?

        opts
      rescue ActionController::RoutingError
        {}
      end

      # Converts an Argu URI into a resource
      # @return [ApplicationRecord, nil] The resource corresponding to the iri, or nil if the IRI is not found
      def resource_from_iri(original_iri, root = nil)
        iri = URI(original_iri)
        raise "A full url is expected. #{iri} is given." if iri.blank? || relative_path?(iri)

        root ||= TenantFinder.from_url(iri)
        opts = opts_from_iri(iri, root)

        resource_from_opts(root, opts) if resource_action?(opts[:action])
      end

      def resource_from_iri!(iri)
        resource_from_iri(iri) || raise(ActiveRecord::RecordNotFound)
      end

      # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def resource_from_opts(root, opts)
        return root if opts[:type] == 'page' && opts[:action] == 'show' && opts[:id].blank?

        opts[:class] ||= ApplicationRecord.descendants.detect { |m| m.to_s == opts[:type].classify } if opts[:type]
        return if opts[:class].blank? || opts[:id].blank?

        ActsAsTenant.with_tenant(root) do
          return shortnameable_from_opts(opts) if shortnameable_from_opts?(opts)
          return linked_record_from_opts(opts) if linked_record_from_opts?(opts)
          return decision_from_opts(opts) if decision_from_opts?(opts)
          return edge_from_opts(opts) if edge_from_opts?(opts)

          resource_by_id_from_opts(opts)
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      private

      def edge_from_opts(opts)
        if uuid?(opts[:id])
          Edge.find_by(uuid: opts[:id])
        else
          Edge.find_by(fragment: opts[:id])
        end
      end

      def edge_from_opts?(opts)
        opts[:class] <= Edge
      end

      def edge_opts(uuid)
        {
          action: 'show',
          type: 'edge',
          id: uuid
        }
      end

      def edge_uuid_from_iri(iri)
        match = uri_template(:edges_iri).match(URI(iri).path).try(:[], 1)

        match if uuid?(match)
      end

      def decision_from_opts(opts)
        return unless opts[:class] == Decision

        Decision
          .joins(:parent)
          .where('parents_edges.root_id = edges.root_id')
          .where(parents_edges: {fragment: opts[parent_resource_key(opts)]})
          .find_by(step: opts[:id])
      end

      def decision_from_opts?(opts)
        opts[:class] == Decision
      end

      def linked_record_from_opts(opts)
        LinkedRecord.find_by(deku_id: opts[:id])
      end

      def linked_record_from_opts?(opts)
        opts[:class] == LinkedRecord && uuid?(opts[:id])
      end

      def opts_from_route(root, iri, method)
        opts = ActsAsTenant.with_tenant(root) do
          Rails.application.routes.recognize_path(sanitized_path(iri, root), method: method)
        end
        opts[:type] = opts[:controller]&.singularize
        opts
      end

      def resource_action?(action)
        %w[show update destroy].include?(action)
      end

      def resource_by_id_from_opts(opts)
        opts[:class].try(:find_by, id: opts[:id])
      end

      def sanitized_path(iri, root)
        iri.path = "#{iri.path}/" unless iri.path.ends_with?('/')

        URI(root.iri.path.present? ? iri.to_s.split("#{root.iri.path}/").last : iri).path
      end

      def shortnameable_from_opts(opts)
        Shortname.find_resource(opts[:id], ActsAsTenant.current_tenant&.uuid) ||
          opts[:class].find_via_shortname_or_id(opts[:id])
      end

      def shortnameable_from_opts?(opts)
        opts[:class].try(:shortnameable?) && !uuid?(opts[:id]) && (/[a-zA-Z]/i =~ opts[:id]).present?
      end
    end
  end
end
