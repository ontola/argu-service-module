# frozen_string_literal: true

class SerializableErrorSerializer < BaseSerializer
  attribute :message, predicate: NS::SCHEMA[:text]

  def rdf_subject
    object.requested_url
  end

  def type
    NS::ARGU["#{object.error.class.name.demodulize}Error"]
  end
end
