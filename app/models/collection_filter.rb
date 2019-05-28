# frozen_string_literal: true

class CollectionFilter < LinkedRails::Collection::Filter
  include LinkedRails::Model

  def iri(_opts = {})
    self
  end
  alias canonical_iri iri
end
