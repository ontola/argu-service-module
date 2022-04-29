# frozen_string_literal: true

module EmpJsonSerializer
  include EmpSerializer::Constants
  include EmpSerializer::Base
  include EmpSerializer::Inclusion
  include EmpSerializer::Records
  include EmpSerializer::Sequence
  include EmpSerializer::RDFList
  include EmpSerializer::Fields
  include EmpSerializer::Slices
  include EmpSerializer::Primitives
end
