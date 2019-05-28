# frozen_string_literal: true

class RDFError < LinkedRails::RDFError
  def initialize(status, requested_url, original_error)
    super
    self.requested_url = ::RDF::DynamicURI(requested_url)
  end
end
