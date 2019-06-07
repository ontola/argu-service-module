# frozen_string_literal: true

class BroadcastWorker
  include Sidekiq::Worker

  def perform(klass, id)
    DataEvent.new(klass.constantize.find(id)).publish
  end
end
