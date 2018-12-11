# frozen_string_literal: true

module Actionable
  module Serializer
    extend ActiveSupport::Concern

    included do
      has_many :actions,
               key: :operation,
               unless: :system_scope?,
               predicate: NS::SCHEMA[:potentialAction],
               graph: NS::LL[:add]
      has_many :favorite_actions,
               unless: :system_scope?,
               predicate: NS::ARGU[:favoriteAction],
               graph: NS::LL[:add]

      triples :action_methods

      def actions
        object.actions(scope).select(&:available?) if scope.is_a?(UserContext)
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
        action_triple(object, NS::ARGU["#{action.tag}_action".camelize(:lower)], action.iri, NS::LL[:add])
      end

      def action_triple(subject, predicate, iri, graph = nil)
        subject_iri = subject.iri
        subject_iri = RDF::DynamicURI(subject_iri.to_s.sub('/lr/', '/od/')) if subject.class.to_s == 'LinkedRecord'
        [subject_iri, predicate, iri, graph]
      end
    end
  end
end
