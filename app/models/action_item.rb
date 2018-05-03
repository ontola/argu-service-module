# frozen_string_literal: true

class ActionItem
  include ActiveModel::Model
  include ActiveModel::Serialization
  include Iriable
  include Ldable

  attr_accessor :label, :type, :target, :parent, :policy, :tag, :resource, :result

  def initialize(attributes = {})
    super
    raise 'A target must be given' if target.blank?
    target.parent = self
  end

  def as_json(_opts = {})
    {}
  end

  def iri(only_path: false)
    base = parent.iri(only_path: only_path)

    if parent.is_a?(Actions::Base)
      base.path += "/#{tag}"
    elsif parent.iri.to_s.include?('#')
      base.fragment = "#{base.fragment}.#{tag}"
    else
      base.fragment = tag
    end
    RDF::URI(base)
  end

  alias id iri
end
