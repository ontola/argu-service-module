# frozen_string_literal: true
require_relative '../../../app/models/concerns/ldable'
require 'active_support/core_ext/hash'

class Resource
  include ActiveModel::Model, Ldable
  alias read_attribute_for_serialization send
  filterable key: {key: :actual_key, values: {value: 'actual_value'}}, key2: {}, key3: {values: {empty: 'NULL'}}

  def initialize(new_record)
    @new_record_before_save = new_record
  end

  def context_id
    id
  end

  def id
    'resource_id'
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
      attr_1: %w(was is),
      attr_2: [nil, 'new'],
      password: %w(old_pass new_pass)
    }
  end
end
