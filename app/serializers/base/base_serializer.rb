# frozen_string_literal: true

class BaseSerializer < ActiveModel::Serializer
  include Ldable::Serializer
  class_attribute :_enums

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

  def never
    false
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

  def self.enum(key, opts = nil)
    self._enums ||= {}
    self._enums[key] = opts

    define_method(key) do
      self.class.enum_options(key) && self.class.enum_options(key)[:options][object.send(key)&.to_sym].try(:[], :iri)
    end
  end

  def self.enum_options(key)
    _enums && _enums[key] || default_enum_opts(key, serializable_class.try(:defined_enums).try(:[], key.to_s))
  end

  def self.default_enum_opts(key, enum_opts)
    return if enum_opts.blank?
    {
      type: NS::SCHEMA[:Thing],
      options: Hash[
        enum_opts&.map { |k, _v| [k.to_sym, {iri: NS::ARGU["form_option/#{key}/#{k}"]}] }
      ]
    }
  end

  def self.serializable_class
    @serializable_class ||= name.gsub('Serializer', '').constantize
  end
end
