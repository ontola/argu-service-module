# frozen_string_literal: true

class EntryPoint
  include ActiveModel::Model
  include ActiveModel::Serialization
  include ChildHelper
  include Ldable
  include Iriable

  attr_accessor :parent
  delegate :form, :description, :url, :http_method, :image, :user_context, :resource, :tag, to: :parent

  def action_body
    target = parent.collection ? child_instance(resource.parent, resource.association_class) : resource
    @action_body ||= form&.new(user_context, target)&.shape
  end

  def as_json(_opts = {})
    {}
  end

  def iri_path(_opts = {})
    u = URI.parse(parent.iri_path)

    if parent.is_a?(Actions::Base)
      u.path += 'entrypoint'
    elsif parent.iri.to_s.include?('#')
      u.fragment += 'entrypoint'
    else
      u.fragment = 'entrypoint'
    end

    u.to_s
  end
  alias id iri

  def label
    var = parent.submit_label
    value = var.respond_to?(:call) ? parent.parent.instance_exec(&var) : var
    value || label_fallback
  end

  private

  def label_fallback
    key = resource.is_a?(Collection) ? resource.association : resource&.class_name
    I18n.t(
      "actions.#{key}.#{tag}.submit",
      default: [:"actions.default.#{tag}.submit", :'actions.default.submit']
    )
  end
end
