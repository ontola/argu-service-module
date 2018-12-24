# frozen_string_literal: true

module RailsLD
  class PropertyQuery < SHACL::PropertyShape
    class << self
      def iri
        NS::ARGU[:PropertyQuery]
      end
    end
  end
end
