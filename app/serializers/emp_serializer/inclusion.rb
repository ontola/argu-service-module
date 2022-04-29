# frozen_string_literal: true

module EmpSerializer
  module Inclusion
    # Modifies the nested_resources parameter
    def collect_nested_resources(nested_resources, slice, resource, value)
      case value
      when LinkedRails::Sequence
        collect_sequence_and_members(nested_resources, slice, resource, value)
      when RDF::List
        nested_resources.push value unless value.subject == NS.rdfv.nil
      when Array
        collect_array_members(nested_resources, slice, resource, value)
      else
        nested_resources.push value if blank_value(value) || nested_resource?(resource, value)
      end
    end

    def collect_sequence_and_members(nested_resources, slice, resource, value)
      value.members.map { |m| collect_nested_resources(nested_resources, slice, resource, m) }
      add_sequence_to_slice(slice, resource: value) unless slice[value.iri.to_s]
    end

    def collect_array_members(nested_resources, slice, resource, value)
      value.each { |m| collect_nested_resources(nested_resources, slice, resource, m) }
    end

    def blank_value(value)
      value.try(:iri)&.is_a?(RDF::Node)
    end

    def nested_resource?(resource, value)
      value.try(:iri)&.to_s&.include?('#') &&
        !resource.iri.to_s.include?('#') &&
        value.iri.to_s.starts_with?(resource.iri.to_s)
    end

    def process_includes(slice, **options) # rubocop:disable Metrics/MethodLength
      includes = options.delete(:includes)
      resource = options.delete(:resource)

      includes.each do |prop, nested|
        value = resource.try(prop)
        next if value.blank?

        if value.is_a?(Array) || value.is_a?(ActiveRecord::Relation)
          value.each { |v| resource_to_emp_json(slice, resource: v, includes: nested, **options) }
        else
          resource_to_emp_json(slice, resource: value, includes: nested, **options)
        end
      end
    end
  end
end
