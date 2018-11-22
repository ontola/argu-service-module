# frozen_string_literal: true

module Updateable
  module Serializer
    extend ActiveSupport::Concern

    included do
      attribute :updated_at,
                predicate: NS::SCHEMA[:dateModified]
    end
  end
end
