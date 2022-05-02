# frozen_string_literal: true

module EmpSerializer
  module Primitives
    include EmpSerializer::Constants

    def object_to_value(value)
      return node_to_local_id(value) if value.is_a?(RDF::Node)

      if model?(value)
        return if value.iri.is_a?(Proc) # TODO: Remove this case (LinkedRails::Ontology::Property)

        return primitive_to_value(value.iri)
      end

      return primitive_to_value(value.subject) if value.is_a?(RDF::List)

      primitive_to_value(value)
    end

    def model?(value)
      value.class < LinkedRails::Model ||
        value.is_a?(LinkedRails::Model::IRI) ||
        value.is_a?(LinkedRails::Sequence) ||
        (value.is_a?(Class) && value < LinkedRails::Model)
    end

    def node_to_local_id(value)
      shorthand(EMP_TYPE_LOCAL_ID, "_:#{value.id}")
    end

    def primitive_to_value(value) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/AbcSize
      case value
      when RDF::Node
        node_to_local_id(value)
      when RDF::URI, URI
        shorthand(EMP_TYPE_GLOBAL_ID, value.to_s)
      when DateTime, ActiveSupport::TimeWithZone
        shorthand(EMP_TYPE_DATETIME, value.iso8601)
      when String
        shorthand(EMP_TYPE_STRING, value)
      when true, false
        shorthand(EMP_TYPE_BOOL, value.to_s)
      when Symbol
        primitive(NS.xsd.token, value.to_s)
      when Integer
        integer_to_value(value)
      when Float, Numeric
        use_rdf_rb_for_primitive(value)
      when RDF::Literal
        rdf_literal_to_value(value)
      else
        throw 'unknown ruby object'
      end
    end

    def integer_to_value(value)
      size = value.bit_length
      if size <= 32
        shorthand(EMP_TYPE_INTEGER, value.to_s)
      elsif size > 32 && size <= 64
        shorthand(EMP_TYPE_LONG, value.to_s)
      else
        use_rdf_rb_for_primitive(value)
      end
    end

    def rdf_literal_to_value(value) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      case value.datatype
      when NS.rdfv.langString
        {
          type: EMP_TYPE_LANGSTRING,
          l: value.language.to_s,
          v: value.value
        }
      when NS.xsd.string
        shorthand(EMP_TYPE_STRING, value.value)
      when NS.xsd.dateTime
        shorthand(EMP_TYPE_DATETIME, value.value)
      when NS.xsd.boolean
        shorthand(EMP_TYPE_BOOL, value.value)
      when NS.xsd.integer
        integer_to_value(value.to_i)
      else
        throw 'unknown RDF::Literal'
      end
    end

    def use_rdf_rb_for_primitive(value)
      rdf = RDF::Literal(value)
      primitive(rdf.datatype.to_s, rdf.value)
    end

    def shorthand(type, value)
      {
        type: type,
        v: value
      }
    end

    def primitive(datatype, value)
      {
        type: EMP_TYPE_PRIMITIVE,
        dt: datatype,
        v: value
      }
    end
  end
end
