# frozen_string_literal: true

class BaseSerializer < ActiveModel::Serializer
  attribute :type, predicate: RDF[:type]
  attribute :canonical_iri, predicate: NS::DC[:identifier]

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
    return if obj.blank?
    if obj.is_a?(MediaObject)
      obj
    elsif obj.is_a?(String)
      obj = RDF::URI(obj.gsub(/^fa-/, 'http://fontawesome.io/icon/'))
      {
        id: obj,
        type: NS::ARGU[:FontAwesomeIcon]
      }
    end
  end

  def service_scope?
    scope&.doorkeeper_scopes&.include? 'service'
  end

  def tenant
    object.forum.url if object.respond_to? :forum
  end

  def type
    object.class.iri
  end
end
