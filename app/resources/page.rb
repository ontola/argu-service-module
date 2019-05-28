# frozen_string_literal: true

class Page < ActiveResourceModel
  include LinkedRails::Model

  def url
    iri_prefix.split('/').last.presence || iri_prefix
  end

  def use_new_frontend
    false
  end
end
