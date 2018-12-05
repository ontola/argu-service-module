# frozen_string_literal: true

class BaseSerializer < ActiveModel::Serializer
  include RailsLD::Serializer
  class_attribute :_enums

  delegate :afe_request?, :export_scope?, :service_scope?, :system_scope?,
           to: :scope,
           allow_nil: true

  def never
    false
  end

  def serialize_image(obj)
    if obj.is_a?(String) || obj.is_a?(Symbol)
      {
        id: RDF::DynamicURI(obj.to_s.gsub(/^fa-/, 'http://fontawesome.io/icon/')),
        type: NS::ARGU[:FontAwesomeIcon]
      }
    elsif obj.is_a?(RDF::URI)
      {id: obj}
    else
      obj.presence
    end
  end

  def tenant
    object.forum.url if object.respond_to? :forum
  end
end
