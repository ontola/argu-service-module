# frozen_string_literal: true

class EntryPoint
  include ActiveModel::Model
  include ActiveModel::Serialization
  include Ldable

  attr_accessor :parent
  delegate :label, :url, :http_method, :image, to: :parent

  def as_json(_opts = {})
    {}
  end

  def iri(only_path: false)
    u = URI.parse(parent.iri(only_path: only_path))

    if parent.is_a?(Actions::Base)
      u.path += 'entrypoint'
    elsif parent.iri.to_s.include?('#')
      u.fragment += 'entrypoint'
    else
      u.fragment = 'entrypoint'
    end

    RDF::URI(u.to_s)
  end
  alias id iri
end
