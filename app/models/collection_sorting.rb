# frozen_string_literal: true

class CollectionSorting < RailsLD::CollectionSorting
  include RailsLD::Model

  def iri(_opts = {})
    self
  end
  alias canonical_iri iri
end
