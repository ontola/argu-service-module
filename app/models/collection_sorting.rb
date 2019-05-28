# frozen_string_literal: true

class CollectionSorting < LinkedRails::Collection::Sorting
  def iri(_opts = {})
    self
  end
  alias canonical_iri iri
end
