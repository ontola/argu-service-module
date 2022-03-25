# frozen_string_literal: true

module Broadcastable
  extend ActiveSupport::Concern

  included do
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

  private

  def should_publish_changes
    !RequestStore.store[:disable_broadcast]
  end
end
