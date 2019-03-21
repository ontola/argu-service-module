# frozen_string_literal: true

module Actionable
  module Serializer
    extend ActiveSupport::Concern

    included do
      has_many :actions,
               key: :operation,
               unless: :system_scope?,
               predicate: NS::SCHEMA[:potentialAction]
      has_many :favorite_actions,
               unless: :system_scope?,
               predicate: NS::ARGU[:favoriteAction]
      triples :action_methods

      def actions
        object_actions + collection_actions
      end

      def action_methods
        triples = []
        actions&.each { |action| triples.append(action_triples(action)) } unless system_scope?
        triples
      end

      def favorite_actions
        actions&.select(&:favorite)
      end

      private

      def action_triples(action)
        action_triple(object, NS::ARGU["#{action.tag}_action".camelize(:lower)], action.iri)
      end

      def action_triple(subject, predicate, iri)
        subject_iri = subject.iri
        subject_iri = RDF::DynamicURI(subject_iri.to_s.sub('/lr/', '/od/')) if subject.class.to_s == 'LinkedRecord'
        [subject_iri, predicate, iri]
      end

      def collection_actions # rubocop:disable Metrics/AbcSize
        return [] unless scope.is_a?(UserContext) && object.collections.present?

        object.collections.map do |opts|
          object.collection_for(opts[:name], user_context: scope).actions(scope).select(&:available?)
        end.flatten
      end

      def object_actions
        scope.is_a?(UserContext) ? object.actions(scope).select(&:available?) : []
      end
    end
  end
end
