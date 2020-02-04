# frozen_string_literal: true

class BaseSerializer < ActiveModel::Serializer
  include LinkedRails::Serializer
  include UriTemplateHelper

  class_attribute :_enums

  delegate :export_scope?, :service_scope?, :system_scope?,
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

  class << self
    # overwrite of LinkedRails::Serializer to enable arrays
    def enum(key, opts = nil) # rubocop:disable Metrics/AbcSize
      self._enums ||= {}
      self._enums[key] = opts

      define_method(key) do
        enum_opts = self.class.enum_options(key).try(:[], :options)
        return if enum_opts.blank?

        raw_value = object.send(key)
        return if raw_value.blank?
        return raw_value.map { |v| enum_opts[v.to_sym].try(:[], :iri) } if raw_value.is_a?(Array)

        enum_opts[raw_value&.to_sym].try(:[], :iri)
      end
    end
  end
end
