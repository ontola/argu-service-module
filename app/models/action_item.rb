# frozen_string_literal: true

class ActionItem
  include ActiveModel::Model
  include ActiveModel::Serialization
  include Ldable

  attr_accessor :label, :type, :target, :parent, :policy, :tag, :resource

  def initialize(attributes = {})
    super
    raise 'A target must be given' if target.blank?
    target.parent = self
  end

  def as_json(_opts = {})
    {}
  end

  def iri
    base = parent.iri

    if parent.is_a?(ActionList)
      base.path += "/#{tag}"
    elsif parent.iri.to_s.include?('#')
      base.fragment = "#{base.fragment}.#{tag}"
    else
      base.fragment = tag
    end
    RDF::IRI.new base
  end
  alias id iri
end
