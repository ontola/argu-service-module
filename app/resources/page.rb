# frozen_string_literal: true

class Page < ActiveResourceModel
  include RailsLD::Model

  def url
    iri_prefix.split('/').last.presence || iri_prefix
  end
end
