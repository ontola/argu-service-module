# frozen_string_literal: true
require_relative '../spec_helper'

describe 'Active resource model' do
  it 'should parse json_api' do
    mock_resource
    resource = Resource.find(1)
    expect(resource.id).to eq('resource_id')
    expect(resource.attr1).to eq('attribute 1')
    expect(resource.parent.id).to eq('record_id')
    expect(resource.parent.attr_one).to eq('attribute one')
  end

  private

  def mock_resource
    stub_request(:get, 'https://argu.test/resources/1')
      .with(headers: {'Accept': 'application/vnd.api+json', 'Authorization': 'Bearer'})
      .to_return(
        status: 200,
        body: {
          data: {
            id: 'resource_id',
            type: 'resources',
            attributes: {
              attr1: 'attribute 1'
            },
            relationships: {
              parent: {
                data: {
                  id: 'record_id',
                  type: 'records'
                }
              }
            }
          },
          included: [
            {
              id: 'record_id',
              type: 'records',
              attributes: {
                attrOne: 'attribute one'
              }
            }
          ]
        }.to_json
      )
  end
end
