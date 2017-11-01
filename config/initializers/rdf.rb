# frozen_string_literal: true

module RDF
  module Term
    def as_json(_opts = {})
      to_s
    end
  end

  class URI
    delegate :present?, to: :to_s
  end
end
