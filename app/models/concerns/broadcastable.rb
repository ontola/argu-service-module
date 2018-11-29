# frozen_string_literal: true

module Broadcastable
  extend ActiveSupport::Concern

  included do
    attr_accessor :broadcastable_changes
    after_commit :publish_data_event, if: :should_broadcast_changes
    after_initialize :reset_broadcastable_changes
    after_save :add_broadcastable_changes
  end

  def publish_data_event
    DataEvent.publish(self)
  end

  def reset_broadcastable_changes
    self.broadcastable_changes = HashWithIndifferentAccess.new
  end

  private

  def add_broadcastable_changes
    previous_changes.each_pair { |k, v| add_broadcastable_change(k, v) }
  end

  def add_broadcastable_change(k, v) # rubocop:disable Metrics/AbcSize
    if !broadcastable_changes.key?(k)
      broadcastable_changes[k] = [safe_dup(v[0]), safe_dup(v[1])]
    elsif broadcastable_changes[k][0] == v[1]
      broadcastable_changes.delete(k)
    else
      broadcastable_changes[k][1] = safe_dup(v[1])
    end
  end

  def safe_dup(v)
    v.dup
  rescue TypeError
    v
  end

  def should_broadcast_changes
    true
  end
end
