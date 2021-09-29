# frozen_string_literal: true

module Broadcastable
  extend ActiveSupport::Concern

  included do
    attr_accessor :broadcastable_changes

    after_commit :publish_data_event, if: :should_broadcast_changes
    after_initialize :reset_broadcastable_changes
    after_save :add_broadcastable_changes

    after_commit :publish_create, on: :create, if: :should_publish_changes
    after_commit :publish_update, on: :update, if: :should_publish_changes
    after_commit :publish_delete, on: :destroy, if: :should_publish_changes
  end

  def publish_create
    publish_message('io.ontola.transactions.Created')
  end

  def publish_update
    publish_message('io.ontola.transactions.Updated')
  end

  def publish_delete
    publish_message('io.ontola.transactions.Deleted')
  end

  def publish_message(type)
    ResourceInvalidationStreamWorker.new.perform(type, iri.to_s, self.class.iri.to_s)
  rescue StandardError
    ResourceInvalidationStreamWorker.perform_async(type, iri.to_s, self.class.iri.to_s)
  end

  # @deprecated Stop using rabbitMQ
  def publish_data_event
    DataEvent.publish(self)
  end

  # @deprecated Stop using rabbitMQ
  def reset_broadcastable_changes
    self.broadcastable_changes = HashWithIndifferentAccess.new
  end

  private

  # @deprecated Stop using rabbitMQ
  def add_broadcastable_changes
    previous_changes.each_pair { |k, v| add_broadcastable_change(k, v) }
  end

  # @deprecated Stop using rabbitMQ
  def add_broadcastable_change(key, val) # rubocop:disable Metrics/AbcSize
    if !broadcastable_changes.key?(key)
      broadcastable_changes[key] = [safe_dup(val[0]), safe_dup(val[1])]
    elsif broadcastable_changes[key][0] == val[1]
      broadcastable_changes.delete(key)
    else
      broadcastable_changes[key][1] = safe_dup(val[1])
    end
  end

  # @deprecated Stop using rabbitMQ
  def safe_dup(val)
    val.dup
  rescue TypeError
    val
  end

  # @deprecated Stop using rabbitMQ
  def should_broadcast_changes
    should_publish_changes
  end

  def should_publish_changes
    !RequestStore.store[:disable_broadcast]
  end
end
