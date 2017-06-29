# frozen_string_literal: true
require_relative '../spec_helper'

describe Resource do
  describe 'json_api parsing' do
    let(:resource) { described_class.find(1) }

    it { expect(resource.id).to eq('resource_id') }
    it { expect(resource.attr1).to eq('attribute 1') }
    it { expect(resource.parent.id).to eq('record_id') }
    it { expect(resource.parent.attr_one).to eq('attribute one') }
  end

  before do
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
