# frozen_string_literal: true

class EntryPoint
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ChildHelper
  include Ldable

  attr_accessor :parent
  delegate :form, :label, :description, :url, :http_method, :image, :user_context, :resource, to: :parent

  def action_body
    target = parent.collection ? child_instance(resource.parent, resource.association_class) : resource
    @action_body ||= form&.new(user_context, target)&.shape
  end

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

    RDF::DynamicURI(u.to_s)
  end
  alias id iri
end
