# frozen_string_literal: true

module EmpSerializer
  module RDFList
    def add_rdf_list_to_slice(slice, **options)
      elem = options.delete(:resource)
      loop do
        record = list_item_to_record(elem)
        slice[record[:_id][:v]] = record
        break if elem.rest_subject == NS.rdfv.nil

        elem = elem.rest
      end
    end

    def list_item_to_record(elem) # rubocop:disable Metrics/AbcSize
      record = create_record(elem)
      record[NS.rdfv.type.to_s] = primitive_to_value(NS.rdfv.List)
      record[NS.rdfv.first.to_s] = primitive_to_value(elem.first)
      record[NS.rdfv.rest.to_s] = primitive_to_value(elem.rest_subject)
      record
    end
  end
end
