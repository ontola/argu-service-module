# frozen_string_literal: true

module EmpSerializer
  module Slices
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
  end
end
