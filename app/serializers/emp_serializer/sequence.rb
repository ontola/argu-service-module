# frozen_string_literal: true

module EmpSerializer
  module Sequence
    def add_sequence_to_slice(slice, **options)
      resource = options.delete(:resource)
      serializer = options[:serializer_class] || RDF::Serializers.serializer_for(resource)

      record = create_record(resource)

      add_attributes_to_record(serializer, slice, resource, record, **options)
      process_sequence_members(serializer, slice, resource, record, **options)

      slice[record[:_id][:v]] = record
    end

    def process_sequence_members(serializer, slice, resource, record, **options)
      index_predicate = serializer.relationships_to_serialize[:members].predicate
      nested = []
      resource.members.each_with_index.map do |m, i|
        record[index_predicate.call(self, i)] = value_to_emp_value(m)
        collect_nested_resources(nested, slice, resource, m)
      end
      nested.map { |r| resource_to_emp_json(slice, resource: r, **options) }
    end
  end
end
