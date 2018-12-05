# frozen_string_literal: true

class CollectionFilter < RailsLD::CollectionFilter
  include RailsLD::Model

  def iri(_opts = {})
    self
  end
  alias canonical_iri iri
end
