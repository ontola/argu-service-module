# frozen_string_literal: true

class CollectionSorting < RailsLD::CollectionSorting
  include Iriable

  def iri(_opts = {})
    self
  end
end
