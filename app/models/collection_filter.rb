# frozen_string_literal: true

class CollectionFilter < RailsLD::CollectionFilter
  include Iriable

  def iri(_opts = {})
    self
  end
  alias canonical_iri iri
end
