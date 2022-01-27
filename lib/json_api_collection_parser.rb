# frozen_string_literal: true

class JsonAPICollectionParser < ActiveResource::Collection
  # rubocop:disable Lint/MissingSuper
  def initialize(elements = [])
    @elements = if elements.is_a?(Hash)
                  elements['data'].map { |record| {'data' => record, 'included' => elements['included']} }
                else
                  elements
                end
  end
  # rubocop:enable Lint/MissingSuper
end
