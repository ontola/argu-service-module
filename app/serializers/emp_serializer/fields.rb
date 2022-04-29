# frozen_string_literal: true

module EmpSerializer
  module Fields
    # Modifies the record parameter
    def add_attributes_to_record(serializer, slice, resource, record, **options) # rubocop:disable Metrics/MethodLength
      return if serializer.attributes_to_serialize.blank?

      nested_resources = []
      serializer.attributes_to_serialize.each do |_, attr|
        next if attr.predicate.blank?

        value = value_for_attribute(attr, resource)
        symbol = predicate_to_symbol(attr, symbolize: options[:symbolize])
        if value.present?
          record[symbol] = value_to_emp_value(value)
          collect_nested_resources(nested_resources, slice, resource, value)
        end
      end

      nested_resources
    end

    # Modifies the record parameter
    def add_statements_to_slice(serializer, slice, resource, **options) # rubocop:disable Metrics/AbcSize
      _statements&.each do |key|
        serializer.send(key, resource, options).each do |statement|
          subject, predicate, value = unpack_statement(statement)

          next if value.nil?

          symbol = uri_to_symbol(predicate, symbolize: options[:symbolize])
          record_id = primitive_to_value(subject)[:v]
          slice[record_id] ||= create_record(subject)
          slice[record_id][symbol] = value_to_emp_value(value)
        end
      end
    end

    # Modifies the record parameter
    def add_relations_to_record(serializer, slice, resource, record, **options) # rubocop:disable Metrics/MethodLength
      return if serializer.relationships_to_serialize.blank?

      nested_resources = []
      serializer.relationships_to_serialize.each do |_, relationship|
        next unless relationship.include_relationship?(resource, @params)

        value = value_for_relation(relationship, resource)
        next if value.nil?

        symbol = predicate_to_symbol(relationship, symbolize: options[:symbolize])
        record[symbol] = value_to_emp_value(value)

        collect_nested_resources(nested_resources, slice, resource, value)
      end

      nested_resources
    end

    def value_for_attribute(attr, resource)
      return resource.try(attr.method) if attr.method.is_a?(Symbol)

      FastJsonapi.call_proc(attr.method, resource, @params)
    end

    def value_for_relation(relation, resource)
      value = unpack_relation_value(relation, resource)

      return if value.nil?

      if relation.sequence
        wrap_relation_in_sequence(value, resource)
      else
        value
      end
    end

    def unpack_relation_value(relation, resource)
      if relation.object_block
        FastJsonapi.call_proc(relation.object_block, resource, @params)
      else
        resource.try(relation.key)
      end
    end

    def wrap_relation_in_sequence(value, resource)
      LinkedRails::Sequence.new(
        value.is_a?(Array) ? value : [value],
        parent: resource,
        scope: false
      )
    end

    def unpack_statement(statement)
      subject = statement.try(:subject) || statement[0]
      predicate = statement.try(:predicate) || statement[1]
      value = statement.try(:object) || statement[2]

      [subject, predicate, value]
    end

    def uri_to_symbol(uri, symbolize: false)
      casing = symbolize == :class ? :upper : :lower

      if symbolize
        (uri.fragment || uri.path.split('/').last).camelize(casing)
      else
        uri.to_s
      end
    end

    def predicate_to_symbol(attr, symbolize: false)
      return uri_to_symbol(attr.predicate, symbolize: symbolize) if attr.predicate.present?

      attr.key
    end

    def value_to_emp_value(value) # rubocop:disable Metrics/MethodLength
      case value
      when ActiveRecord::Associations::CollectionProxy
        value.map { |iri| object_to_value(iri) }.compact
      when LinkedRails::Sequence
        object_to_value(value.iri)
      when RDF::List
        object_to_value(value.subject)
      when Array, ActiveRecord::Relation
        value.map { |v| object_to_value(v) }.compact
      else
        object_to_value(value)
      end
    end
  end
end
