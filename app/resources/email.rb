# frozen_string_literal: true
class Email < ActiveResourceModel
  def self.collection_name
    'email/emails'
  end

  %w(opened accepted rejected delivered failed clicked unsubscribed complained stored).each do |event|
    define_method "#{event}?" do
      email_tracking_events.any? { |e| e.event == event }
    end
  end

  def status
    return 'delivered' if delivered?
    'failed' if failed?
  end
end
