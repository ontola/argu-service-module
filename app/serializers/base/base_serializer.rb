# frozen_string_literal: true

class BaseSerializer < ActiveModel::Serializer
  include Ldable::Serializer

  attribute :type, predicate: RDF[:type]
  attribute :canonical_iri, predicate: NS::DC[:identifier]

  delegate :afe_request?, :export_scope?, :service_scope?, :system_scope?,
           to: :scope,
           allow_nil: true

  def id
    rdf_subject
  end

  def canonical_iri
    object.try(:canonical_iri) || rdf_subject
  end

  def rdf_subject
    object.iri
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

  def type
    object.class.iri
  end
end
