# frozen_string_literal: true

class BaseSerializer
  include RDF::Serializers::ObjectSerializer
  include LinkedRails::Serializer

  class_attribute :_enums

  %i[export_scope? service_scope? system_scope?].each do |method|
    define_singleton_method(method) do |_object, params|
      params[:scope]&.send(method)
    end
  end

  class << self
    # overwrite of LinkedRails::Serializer to enable arrays
    def enum_value(key, enum_opts, object)
      raw_value = object.send(key)

      if raw_value.is_a?(Array)
        raw_value.map { |v| enum_opts[v.to_sym].try(:[], :iri) }
      elsif raw_value.present?
        enum_opts[raw_value&.to_sym].try(:[], :iri)
      end
    end

    def never(_object, _params)
      false
    end

    def validate_includes!(_includes); end
  end
end
