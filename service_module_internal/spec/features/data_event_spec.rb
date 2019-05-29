# frozen_string_literal: true

require_relative '../spec_helper'

shared_examples_for 'parsing event' do
  it { expect(data_event.resource_id).to eq(expected_id) }
  it { expect(data_event.resource_type).to eq(expected_type) }
  it { expect(data_event.event).to eq(expected_event) }
  it { expect(data_event.resource).to match(expected_attributes) }
  it { expect(data_event.affected_resources).to match(expected_affected_resources) }
  it { expect(data_event.changes).to match(expected_changes) }
end

describe DataEvent do
  let(:expected_id) { 'record_id' }
  let(:expected_type) { 'records' }

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
          id: 'http://app.argu.localtest/argu/records/record_id',
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
    let(:expected_event) { 'update' }
    let(:expected_attributes) do
      {
        id: 'record_id',
        type: 'records',
        attributes: {
          attr1: 'is',
          attr2: 'new'
        }
      }
    end
    let(:expected_affected_resources) do
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
    let(:expected_changes) do
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

    it_behaves_like 'parsing event'
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
    let(:expected_event) { 'create' }
    let(:expected_attributes) do
      {
        id: 'record_id',
        type: 'records',
        attributes: {
          attr1: 'is',
          attr2: 'new'
        }
      }
    end
    let(:expected_affected_resources) do
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
    let(:expected_changes) { nil }

    it_behaves_like 'parsing event'
  end

  describe 'destroy event parsing' do
    let(:data_event) do
      described_class.parse(
        {
          data: {
            type: 'destroyEvent',
            attributes: {
              changes: nil
            },
            relationships: {
              resource: {
                data: {
                  id: 'record_id',
                  type: 'records'
                }
              }
            }
          }
        }.to_json
      )
    end
    let(:expected_event) { 'destroy' }
    let(:expected_changes) { nil }
    let(:expected_attributes) { nil }
    let(:expected_affected_resources) { nil }

    it_behaves_like 'parsing event'
  end
end
