# frozen_string_literal: true
require_relative '../spec_helper'

describe 'DataEvents' do
  it 'should publish new resource' do
    body = JSON.parse(DataEvent.new(Record.new(true)).publish)
    expect(body['data']['type']).to eq('createEvent')
    expect(body['data']['attributes']['changes']).to be_nil
    expect(body['data']['relationships'].keys).to include('resource')
    expect(body['included'].first['attributes']).to eq('attr1' => 'is', 'attr2' => 'new')
  end

  it 'should publish updated resource' do
    body = JSON.parse(DataEvent.new(Record.new(false)).publish)
    expect(body['data']['type']).to eq('updateEvent')
    expect(body['data']['attributes']['changes']).to(
      match(
        [
          {
            id: 'record_id',
            type: 'records',
            attributes: {'attr1' => %w(was is), 'attr2' => [nil, 'new'], 'password' => '[FILTERED]'}
          }.with_indifferent_access
        ]
      )
    )
    expect(body['data']['relationships'].keys).to include('resource')
    expect(body['included'].first['attributes']).to eq('attr1' => 'is', 'attr2' => 'new')
  end

  it 'should parse update event' do
    data_event = DataEvent.parse(
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
                  attr1: %w(was is),
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
    expect(data_event.resource_id).to eq('record_id')
    expect(data_event.resource_type).to eq('records')
    expect(data_event.event).to eq('update')
    expect(data_event.resource).to(
      match(
        id: 'record_id',
        type: 'records',
        attributes: {
          attr1: 'is',
          attr2: 'new'
        }
      )
    )
    expect(data_event.affected_resources).to(
      match(
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
      )
    )
    expect(data_event.changes).to(
      match(
        [
          {
            id: 'record_id',
            type: 'records',
            attributes: [
              attr1: %w(was is),
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
      )
    )
  end

  it 'should parse create event' do
    data_event = DataEvent.parse(
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
    expect(data_event.resource_id).to eq('record_id')
    expect(data_event.resource_type).to eq('records')
    expect(data_event.event).to eq('create')
    expect(data_event.resource).to(
      match(
        id: 'record_id',
        type: 'records',
        attributes: {
          attr1: 'is',
          attr2: 'new'
        }
      )
    )
    expect(data_event.affected_resources).to(
      match(
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
      )
    )
    expect(data_event.changes).to be_nil
  end
end
