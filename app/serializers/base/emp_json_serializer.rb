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

  def render_emp_json(*args, **options)
    Oj.fast_generate(create_slice(**args[1], **options))
  end

  def create_slice(**options)
    slice = {}

    resource_to_emp_json(slice, **options)

    slice
  end

  def resource_to_emp_json(slice, **options)
    resource = options.delete(:resource)
    serializer = options[:serializer_class] || RDF::Serializers.serializer_for(resource)

    record = create_record(resource)
    serialize_attributes(serializer, resource, record, **options)
    serialize_relations(serializer, resource, record, **options)

    slice[record[:_id].to_s] = record
    process_includes(slice, resource: resource, **options) if options[:include]

    record
  end

  def create_record(resource)
    {
      "_id": record_id(resource)
    }
  end

  def record_id(resource)
    iri = resource.try(:iri)
    return iri.id if iri.is_a?(RDF::Node)

    iri&.to_s || resource.id
  end

  # Modifies the record parameter
  def serialize_attributes(serializer, resource, record, **options)
    return if serializer.attributes_to_serialize.blank?

    serializer.attributes_to_serialize.each do |_, attr|
      next if attr.key == :rdf_type || attr.predicate.blank?

      value = value_for_attr(attr, resource)
      symbol = predicate_to_symbol(attr, symbolize: options[:symbolize])
      record[symbol] = value_to_emp_json(value) if value.present?
    end
  end

  def value_for_attr(attr, resource)
    return resource.try(attr.method) if attr.method.is_a?(Symbol)

    attr.method&.call(resource)
  end

  # Modifies the record parameter
  def serialize_relations(serializer, resource, record, **options)
    return if serializer.relationships_to_serialize.blank?

    serializer.relationships_to_serialize.each do |_, relationship|
      value = value_for_relation(relationship, resource)
      if value.present?
        record[predicate_to_symbol(relationship, symbolize: options[:symbolize])] = value_to_emp_json(value)
      end
    end
  end

  def value_for_relation(attr, resource)
    resource.try(attr.key)
  end

  def process_includes(slice, **options) # rubocop:disable Metrics/MethodLength
    include = options.delete(:include)
    resource = options.delete(:resource)

    include.each do |prop|
      value = resource.try(prop)
      next if value.blank?

      if value.is_a?(Array)
        value.each { |v| resource_to_emp_json(slice, resource: v, **options) }
      else
        resource_to_emp_json(slice, resource: value, **options)
      end
    end
  end

  def predicate_to_symbol(attr, symbolize: false)
    casing = symbolize == :class ? :upper : :lower

    if symbolize && attr.predicate.present?
      (attr.predicate.fragment || attr.predicate.path.split('/').last).camelize(casing)
    elsif symbolize
      attr.name.to_s.camelize(casing)
    else
      attr.predicate.to_s
    end
  end

  def value_to_emp_json(value)
    case value
    when ActiveRecord::Associations::CollectionProxy
      value.iri.map { |iri| primitive_to_emp_json(iri) }
    when Array
      value.map { |v| primitive_to_emp_json(v) }
    else
      primitive_to_emp_json(value)
    end
  end

  def primitive_to_emp_json(value) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
    case value
    when LinkedRails::Model::IRI
      primitive_to_emp_json(value.iri)
    when RDF::URI
      emp_short_value(EMP_TYPE_GLOBAL_ID, value.to_s)
    when ActiveSupport::TimeWithZone
      emp_short_value(EMP_TYPE_DATETIME, value.iso8601)
    when String
      emp_short_value(EMP_TYPE_STRING, value)
    when true, false
      emp_short_value(EMP_TYPE_BOOL, value)
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
