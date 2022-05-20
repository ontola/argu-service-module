# frozen_string_literal: true

class BaseSerializer
  include RDF::Serializers::ObjectSerializer
  include LinkedRails::Serializer
  include LinkedRails::EmpJSON::Instrument

  def render_emp_json
    instrumented_render_emp_json
  end

  class_attribute :_enums

  %i[export_scope? service_scope? system_scope?].each do |method|
    define_singleton_method(method) do |_object, params|
      params[:scope]&.send(method)
    end
  end

  class << self
    def count_attribute(type, **opts)
      attribute "#{type}_count",
                {predicate: NS.argu["#{type.to_s.camelcase(:lower)}Count".to_sym]}.merge(opts) do |object, params|
        block_given? ? yield(object, params) : object.children_count(type)
      end
    end

    # overwrite of LinkedRails::Serializer to enable arrays
    def enum_value(key, object)
      options = enum_options(key)
      return if options.blank?

      raw_value = object.send(key)

      if raw_value.is_a?(Array)
        raw_value.map { |v| options[v.to_sym].try(:iri) }
      elsif raw_value.present?
        options[raw_value].try(:iri)
      end
    end

    def money_attribute(key, opts)
      attribute key, opts do |object|
        object.send(key)&.cents
      end
    end
  end
end
