# frozen_string_literal: true

module EmpSerializer
  module Base
    def resource_to_emp_json(slice, **options)
      return if record_id(options[:resource])&.is_a?(Proc)

      return add_sequence_to_slice(slice, **options) if options[:resource].is_a?(LinkedRails::Sequence)
      return add_rdf_list_to_slice(slice, **options) if options[:resource].is_a?(RDF::List)

      add_record_to_slice(slice, **options)
    end
  end
end
