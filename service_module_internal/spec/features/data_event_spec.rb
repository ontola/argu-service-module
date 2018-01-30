# frozen_string_literal: true

require_relative '../spec_helper'

describe DataEvent do
  describe 'new resource' do
    let(:body) { JSON.parse(described_class.new(Record.new(true)).publish) }

    it { expect(body['data']['type']).to eq('createEvent') }
    it { expect(body['data']['attributes']['changes']).to be_nil }
    it { expect(body['data']['relationships'].keys).to include('resource') }
    it { expect(body['included'].first['attributes']).to eq('attr1' => 'is', 'attr2' => 'new') }
  end

  describe 'publish updated resource' do
    let(:body) { JSON.parse(described_class.new(Record.new(false)).publish) }
    let(:changes) do
      [
        {
          id: 'https://argu.test/r/record_id',
          type: 'records',
          attributes: {'attr1' => %w[was is], 'attr2' => [nil, 'new'], 'password' => '[FILTERED]'}
        }.with_indifferent_access
      ]
    end

    it { expect(body['data']['type']).to eq('updateEvent') }
    it { expect(body['data']['attributes']['changes']).to(match(changes)) }
    it { expect(body['data']['relationships'].keys).to include('resource') }
    it { expect(body['included'].first['attributes']).to eq('attr1' => 'is', 'attr2' => 'new') }
  end

  describe 'update event parsing' do
    let(:data_event) do
      described_class.parse(
        {
          data: {
            id: '',
            type: 'updateEvent',
            attributes: {
              changes: [
                {
                  id: 'record_id',
                  type: 'records',
                  attributes: [
                    attr1: %w[was is],
                    attr2: [nil, 'new']
                  ]
                },
                {
                  id: 'affected_resource_1',
                  type: 'resources',
                  attributes: [
                    attr: [nil, 'r1']
                  ]
                },
                {
                  id: 'affected_resource_2',
                  type: 'resources',
                  attributes: [
                    attr: [nil, 'r2']
                  ]
                }
              ]
            },
            relationships: {
              resource: {
                data: {
                  id: 'record_id',
                  type: 'records'
                }
              },
              affected_resources: [
                {
                  data: {
                    id: 'affected_resource_1',
                    type: 'resources'
                  }
                },
                {
                  data: {
                    id: 'affected_resource_2',
                    type: 'resources'
                  }
                }
              ]
            }
          },
          included: [
            {
              id: 'record_id',
              type: 'records',
              attributes: {
                attr1: 'is',
                attr2: 'new'
              }
            },
            {
              id: 'affected_resource_2',
              type: 'resources',
              attributes: {
                attr: 'r2'
              }
            },
            {
              id: 'affected_resource_1',
              type: 'resources',
              attributes: {
                attr: 'r1'
              }
            }
          ]
        }.to_json
      )
    end
    let(:resource_attributes) do
      {
        id: 'record_id',
        type: 'records',
        attributes: {
          attr1: 'is',
          attr2: 'new'
        }
      }
    end
    let(:affected_resources_attributes) do
      [
        {
          id: 'affected_resource_1',
          type: 'resources',
          attributes: {
            attr: 'r1'
          }
        },
        {
          id: 'affected_resource_2',
          type: 'resources',
          attributes: {
            attr: 'r2'
          }
        }
      ]
    end
    let(:data_event_changes) do
      [
        {
          id: 'record_id',
          type: 'records',
          attributes: [
            attr1: %w[was is],
            attr2: [nil, 'new']
          ]
        },
        {
          id: 'affected_resource_1',
          type: 'resources',
          attributes: [
            attr: [nil, 'r1']
          ]
        },
        {
          id: 'affected_resource_2',
          type: 'resources',
          attributes: [
            attr: [nil, 'r2']
          ]
        }
      ]
    end

    it { expect(data_event.resource_id).to eq('record_id') }
    it { expect(data_event.resource_type).to eq('records') }
    it { expect(data_event.event).to eq('update') }
    it { expect(data_event.resource).to match(resource_attributes) }
    it { expect(data_event.affected_resources).to match(affected_resources_attributes) }
    it { expect(data_event.changes).to match(data_event_changes) }
  end

  describe 'create event parsing' do
    let(:data_event) do
      described_class.parse(
        {
          data: {
            id: '',
            type: 'createEvent',
            attributes: {
            },
            relationships: {
              resource: {
                data: {
                  id: 'record_id',
                  type: 'records'
                }
              },
              affected_resources: [
                {
                  data: {
                    id: 'affected_resource_1',
                    type: 'resources'
                  }
                },
                {
                  data: {
                    id: 'affected_resource_2',
                    type: 'resources'
                  }
                }
              ]
            }
          },
          included: [
            {
              id: 'record_id',
              type: 'records',
              attributes: {
                attr1: 'is',
                attr2: 'new'
              }
            },
            {
              id: 'affected_resource_2',
              type: 'resources',
              attributes: {
                attr: 'r2'
              }
            },
            {
              id: 'affected_resource_1',
              type: 'resources',
              attributes: {
                attr: 'r1'
              }
            }
          ]
        }.to_json
      )
    end
    let(:resource_attributes) do
      {
        id: 'record_id',
        type: 'records',
        attributes: {
          attr1: 'is',
          attr2: 'new'
        }
      }
    end
    let(:affected_resources_attributes) do
      [
        {
          id: 'affected_resource_1',
          type: 'resources',
          attributes: {
            attr: 'r1'
          }
        },
        {
          id: 'affected_resource_2',
          type: 'resources',
          attributes: {
            attr: 'r2'
          }
        }
      ]
    end

    it { expect(data_event.resource_id).to eq('record_id') }
    it { expect(data_event.resource_type).to eq('records') }
    it { expect(data_event.event).to eq('create') }
    it { expect(data_event.resource).to match(resource_attributes) }
    it { expect(data_event.affected_resources).to match(affected_resources_attributes) }
    it { expect(data_event.changes).to be_nil }
  end
end
