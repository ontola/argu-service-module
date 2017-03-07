# frozen_string_literal: true
require_relative '../spec_helper'

describe 'Collections' do
  it 'should build filter_query' do
    collection = Collection.new(
      association: :resource,
      association_class: Record,
      filter: {key: :value, key2: 'value2', key3: 'empty'}
    )
    expect(collection.send(:filter_query)).to(
      eq(['actual_key = ? AND key2 = ? AND key3 IS NULL', 'actual_value', 'value2'])
    )
  end
end
