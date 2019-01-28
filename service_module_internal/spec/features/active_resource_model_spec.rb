# frozen_string_literal: true

require_relative '../spec_helper'

describe Resource do
  describe 'json_api parsing' do
    let(:resource) { described_class.find(1) }

    it { expect(resource.id).to eq('resource_id') }
    it { expect(resource.attr1).to eq('attribute 1') }
    it { expect(resource.parent.id).to eq('ping') }
    it { expect(resource.parent.attr_one).to eq('I am ping') }
    it { expect(resource.parent.parent.id).to eq('pong') }
    it { expect(resource.parent.parent.attr_one).to eq('I am pong') }
    it { expect(resource.parent.parent.parent.id).to eq('ping') }
    it { expect(resource.parent2.id).to eq('ping') }
    it { expect(resource.parent2.attr_one).to eq('I am ping') }
  end

  before do
    extend ServiceHelper

    stub_request(:get, expand_service_url(:argu, '/resources/1'))
      .with(headers: {'Accept': 'application/vnd.api+json'})
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
                  id: 'ping',
                  type: 'records'
                }
              },
              parent2: {
                data: {
                  id: 'ping',
                  type: 'records'
                }
              }
            }
          },
          included: [
            {
              id: 'ping',
              type: 'records',
              attributes: {
                attrOne: 'I am ping'
              },
              relationships: {
                parent: {
                  data: {
                    id: 'pong',
                    type: 'records'
                  }
                }
              }
            },
            {
              id: 'pong',
              type: 'records',
              attributes: {
                attrOne: 'I am pong'
              },
              relationships: {
                parent: {
                  data: {
                    id: 'ping',
                    type: 'records'
                  }
                }
              }
            }
          ]
        }.to_json
      )
  end
end
