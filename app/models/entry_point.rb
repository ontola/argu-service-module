# frozen_string_literal: true

class EntryPoint
  include ActiveModel::Model
  include ActiveModel::Serialization
  include Ldable

  attr_accessor :http_method, :image, :label, :label_params, :parent, :tag,
                :type, :resource, :url, :url_template

  def as_json(_opts = {})
    {}
  end

  def iri
    u = URI.parse(parent.iri)

    if parent.is_a?(ActionList)
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
