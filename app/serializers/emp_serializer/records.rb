# frozen_string_literal: true

module EmpSerializer
  module Records
    def add_record_to_slice(slice, **options)
      resource = options.delete(:resource)
      serializer = options.delete(:serializer_class) || RDF::Serializers.serializer_for(resource)

      record, nested = build_record(serializer, slice, resource, **options)

      slice[record[:_id][:v]] = record
      nested.map { |r| resource_to_emp_json(slice, resource: r, **options) }
      process_includes(slice, resource: resource, **options) if options[:includes]

      slice[record[:_id][:v]] = record
    end

    def build_record(serializer, slice, resource, **options)
      record = create_record(resource)
      nested = add_attributes_to_record(serializer, slice, resource, record, **options)
      nested += add_relations_to_record(serializer, slice, resource, record, **options)

      add_statements_to_slice(serializer, slice, resource, **options)

      [record, nested]
    end

    def create_record(resource)
      id = resource.is_a?(RDF::Resource) ? resource : record_id(resource)

      {
        "_id": primitive_to_value(id)
      }
    end

    def record_id(resource)
      return resource.to_s if resource.is_a?(URI)

      resource.try(:iri) || resource.try(:subject) || resource.id
    end
  end
end
