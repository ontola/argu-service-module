class JsonApiCollectionParser < ActiveResource::Collection
  def initialize(elements = [])
    @elements = if elements.is_a?(Hash)
                  elements['data'].map { |record| {'data' => record, 'included' => elements['included']}}
                else
                  elements
                end
  end
end
