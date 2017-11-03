# frozen_string_literal: true

class BaseSerializer < ActiveModel::Serializer
  attribute :type, predicate: RDF[:type]

  def id
    ld_id
  end

  def ld_id
    object.iri
  end

  def service_scope?
    scope&.doorkeeper_scopes&.include? 'service'
  end

  def tenant
    object.forum.url if object.respond_to? :forum
  end

  def type
    NS::ARGU[object.class.name]
  end
end
