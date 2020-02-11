# frozen_string_literal: true

class HexAdapter < ActiveModelSerializers::Adapter::RDF
  def dump
    repository.map { |s| Oj.fast_generate(s) }.join("\n")
  end

  private

  def add_attribute(subject, predicate, value, graph)
    return unless predicate

    normalized = value.is_a?(Array) ? value : [value]
    normalized.compact.each do |v|
      add_statement [subject, predicate, v, graph]
    end
  end

  def add_statement(statement)
    @repository <<
      if statement.is_a?(Array) && statement.length != 6
        rdf_array_to_hex(statement)
      elsif statement.is_a?(Array)
        statement
      else
        rdf_statement_to_hex(statement)
      end
  end

  def custom_statements_for(serializer)
    serializer.class.try(:_statements)&.each do |key|
      serializer.read_attribute_for_serialization(key).each do |statement|
        add_statement(statement)
      end
    end
  end

  def from_class(obj)
    ActiveSupport::Inflector
      .pluralize(obj.class.name.underscore)
      .gsub('/', ActiveModelSerializers.config.jsonapi_namespace_separator)
  end

  def normalized_object(object) # rubocop:disable Metrics/MethodLength
    case object
    when ::RDF::Term
      object
    when ::RDF::List
      list = object.statements
      object.statements.each { |s| add_statement(s) }
      list.first.subject
    when ActiveSupport::TimeWithZone
      ::RDF::Literal(object.to_datetime)
    else
      ::RDF::Literal(object)
    end
  end

  def object_datatype(obj)
    if obj.is_a?(::RDF::URI)
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#namedNode'
    elsif obj.is_a?(::RDF::Node)
      'http://www.w3.org/1999/02/22-rdf-syntax-ns#blankNode'
    else
      obj.datatype
    end
  end

  def object_value(obj)
    if obj.is_a?(::RDF::URI)
      obj.value
    elsif obj.is_a?(::RDF::Node)
      obj.to_s
    else
      obj.value.to_s
    end
  end

  def rdf_array_to_hex(statement)
    obj = normalized_object(statement[2])
    [
      object_value(statement[0]),
      statement[1].value,
      object_value(obj),
      object_datatype(obj),
      obj.try(:language) || '',
      statement[3]&.value || ::RDF::Serializers.config.default_graph.value
    ]
  end

  def rdf_statement_to_hex(statement)
    obj = normalized_object(statement.object)
    [
      object_value(statement.subject),
      statement.predicate.value,
      object_value(obj),
      object_datatype(obj),
      obj.try(:language) || '',
      statement.graph_name&.value || ::RDF::Serializers.config.default_graph.value
    ]
  end

  def repository
    return @repository if @repository.present?

    @repository = []

    serializers.each { |serializer| process_resource(serializer, @include_directive) }
    serializers.each { |serializer| process_relationships(serializer, @include_directive) }
    instance_options[:meta]&.each { |meta| add_statement(meta) }

    @repository
  end

  def type_for(serializer, _instance_options)
    raw = serializer._type || from_class(serializer.object)
    CaseTransform.camel_lower(raw)
  end
end

ActionController::Renderers.add :hndjson do |resource, options|
  get_serializer(resource, options.merge(adapter: :hex_adapter)).adapter.dump
end
