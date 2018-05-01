# frozen_string_literal: true

# rubocop:disable Rails/ApplicationRecord:
class Record < ActiveRecord::Base
  extend ActiveRecord::Delegation::DelegateCache

  include Ldable
  include Iriable
  include ActiveModel::Model
  alias read_attribute_for_serialization send
  filterable key: {key: :actual_key, values: {value: 'actual_value'}}, key2: {}, key3: {values: {empty: 'NULL'}}

  def initialize(new_record)
    @new_record_before_save = new_record
  end

  def id
    'record_id'
  end

  def as_json(_options = {})
    {}
  end

  def attr_1
    'is'
  end

  def attr_2
    'new'
  end

  def previous_changes
    {
      attr_1: %w[was is],
      attr_2: [nil, 'new'],
      password: %w[old_pass new_pass]
    }
  end
end
# rubocop:enable Rails/ApplicationRecord:
