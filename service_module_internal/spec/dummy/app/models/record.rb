# frozen_string_literal: true

class Record < ApplicationRecord
  include LinkedRails::Model
  with_collection :records

  alias read_attribute_for_serialization send
  filterable key: {key: :actual_key, values: {value: 'actual_value'}}, key2: {}, key3: {values: {empty: 'NULL'}}

  def as_json(_options = {})
    {}
  end

  def self.default_per_page
    11
  end
end
