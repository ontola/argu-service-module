# frozen_string_literal: true

module EmpJsonSerializer
  EMP_TYPE_GLOBAL_ID = 'id'
  EMP_TYPE_LOCAL_ID = 'lid'
  EMP_TYPE_DATETIME = 'dt'
  EMP_TYPE_STRING = 's'
  EMP_TYPE_BOOL = 'b'
  EMP_TYPE_INTEGER = 'i'
  EMP_TYPE_LONG = 'l'
  EMP_TYPE_PRIMITIVE = 'p'
  EMP_TYPE_LANGSTRING = 'ls'

  def render_emp_json
    Oj.fast_generate(emp_json_hash)
  end

  def emp_json_hash
    create_slice(resource: @resource, includes: @includes)
  end

  def create_slice(**options)
    slice = {}

    resource_to_emp_json(slice,
                         **options,
                         serializer_class: self.class,
                         includes: @rdf_includes)

    slice
  end

  def resource_to_emp_json(slice, **options)
    return if options[:resource].iri.is_a?(Proc)

    return sequence_to_emp_json(slice, **options) if options[:resource].is_a?(LinkedRails::Sequence)

    record_to_emp_json(slice, **options)
  end

  def sequence_to_emp_json(slice, **options)
    resource = options.delete(:resource)
    serializer = options[:serializer_class] || RDF::Serializers.serializer_for(resource)

    record = create_record(resource)
    serialize_attributes(serializer, resource, record, **options)

    index_predicate = serializer.relationships_to_serialize[:members].predicate
    resource.members.each_with_index.map do |m, i|
      record[index_predicate.call(self, i)] = value_to_emp_json(m)
    end

    slice[record[:_id][:v]] = record
  end

  def record_to_emp_json(slice, **options)
    resource = options.delete(:resource)
    serializer = options.delete(:serializer_class) || RDF::Serializers.serializer_for(resource)

    record = create_record(resource)
    serialize_attributes(serializer, resource, record, **options)
    serialize_statements(serializer, resource, record, **options)
    nested = serialize_relations(serializer, resource, record, **options)

    slice[record[:_id][:v]] = record
    nested.map { |r| resource_to_emp_json(slice, resource: r, **options) }
    process_includes(slice, resource: resource, **options) if options[:includes]

    slice[record[:_id][:v]] = record
  end

  def create_record(resource)
    {
      "_id": primitive_to_emp_json(record_id(resource))
    }
  end

  def record_id(resource)
    iri = resource.try(:iri)
    return "_:#{iri.id}" if iri.is_a?(RDF::Node)

    iri&.to_s || resource.id
  end

  # Modifies the record parameter
  def serialize_attributes(serializer, resource, record, **options)
    return if serializer.attributes_to_serialize.blank?

    serializer.attributes_to_serialize.each do |_, attr|
      next if attr.predicate.blank?

      value = value_for_attr(attr, resource)
      symbol = predicate_to_symbol(attr, symbolize: options[:symbolize])
      record[symbol] = value_to_emp_json(value) if value.present?
    end
  end

  def value_for_attr(attr, resource)
    return resource.try(attr.method) if attr.method.is_a?(Symbol)

    attr.method&.call(resource)
  end

  def serialize_statements(serializer, resource, record, **options)
    _statements&.each do |key|
      serializer.send(key, resource, options).each do |statement|
        predicate = statement.try(:predicate) || statement[1]
        value = statement.try(:object) || statement[2]

        next if value.blank?

        symbol = uri_to_symbol(predicate, symbolize: options[:symbolize])
        record[symbol] = value_to_emp_json(value) if value.present?
      end
    end
  end

  # Modifies the record parameter
  def serialize_relations(serializer, resource, record, **options)
    return if serializer.relationships_to_serialize.blank?

    nested_resources = []
    serializer.relationships_to_serialize.each do |_, relationship|
      next unless relationship.include_relationship?(resource, @params)

      value = value_for_relation(relationship, resource)
      next if value.nil?

      symbol = predicate_to_symbol(relationship, symbolize: options[:symbolize])
      record[symbol] = value_to_emp_json(value)

      add_nested_resources(nested_resources, resource, value)
    end

    nested_resources
  end

  def add_nested_resources(nested_resources, resource, value)
    case value
    when LinkedRails::Sequence
      value.members.map { |m| add_nested_resources(nested_resources, resource, m) }
    when Array
      value.map { |m| add_nested_resources(nested_resources, resource, m) }
    else
      nested_resources.push value if blank_value(value) || nested_resource?(resource, value)
    end
  end

  def blank_value(value)
    value.try(:iri)&.is_a?(RDF::Node)
  end

  def nested_resource?(resource, value)
    value.try(:iri)&.to_s&.include?('#') &&
      !resource.iri.to_s.include?('#') &&
      value.iri.to_s.starts_with?(resource.iri.to_s)
  end

  def value_for_relation(attr, resource)
    return FastJsonapi.call_proc(attr.object_block, resource, @params) if attr.object_block

    value = resource.try(attr.key)
    return if value.nil?

    if attr.sequence
      LinkedRails::Sequence.new(
        value.is_a?(Array) ? value : [value],
        parent: resource,
        scope: false
      )
    else
      value
    end
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

  def uri_to_symbol(uri, symbolize: false)
    casing = symbolize == :class ? :upper : :lower

    if symbolize
      (uri.fragment || uri.path.split('/').last).camelize(casing)
    else
      uri.to_s
    end
  end

  def predicate_to_symbol(attr, symbolize: false)
    uri_to_symbol(uri, symbolize: symbolize) if symbolize && attr.predicate.blank?

    uri_to_symbol(attr.predicate)
  end

  def value_to_emp_json(value)
    case value
    when ActiveRecord::Associations::CollectionProxy
      value.map { |iri| primitive_to_emp_json(iri) }.compact
    when LinkedRails::Sequence
      primitive_to_emp_json(value.iri)
    when Array, ActiveRecord::Relation, RDF::List
      value.map { |v| primitive_to_emp_json(v) }.compact
    else
      primitive_to_emp_json(value)
    end
  end

  def primitive_to_emp_json(value) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
    case value
    when RDF::Node
      emp_short_value(EMP_TYPE_LOCAL_ID, value.to_s)
    when LinkedRails::Model::IRI, LinkedRails::Sequence
      return if value.iri.is_a?(Proc) # TODO: Remove this case

      primitive_to_emp_json(value.iri)
    when RDF::URI, URI
      emp_short_value(EMP_TYPE_GLOBAL_ID, value.to_s)
    when ActiveSupport::TimeWithZone
      emp_short_value(EMP_TYPE_DATETIME, value.iso8601)
    when String
      emp_short_value(EMP_TYPE_STRING, value)
    when true, false
      emp_short_value(EMP_TYPE_BOOL, value)
    when Symbol
      {
        type: EMP_TYPE_PRIMITIVE,
        dt: NS.xsd.token,
        v: value.to_s
      }
    when Numeric
      rdf = RDF::Literal(value)
      if rdf.datatype == NS.xsd.integer
        emp_short_value(EMP_TYPE_INTEGER, rdf.value)
      elsif rdf.datatype == NS.xsd.long
        emp_short_value(EMP_TYPE_LONG, rdf.value)
      else
        {
          type: EMP_TYPE_PRIMITIVE,
          dt: rdf.datatype.to_s,
          v: rdf.value
        }
      end
    when RDF::Literal
      case value.datatype
      when RDF::URI('http://www.w3.org/1999/02/22-rdf-syntax-ns#langString')
        {
          type: EMP_TYPE_LANGSTRING,
          l: value.language,
          v: value.value
        }
      else
        throw 'unknown RDF::Literal'
      end
    else
      throw 'unknown ruby object'
    end
  end

  def emp_short_value(type, value)
    {
      type: type,
      v: value
    }
  end
end
