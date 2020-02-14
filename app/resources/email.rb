# frozen_string_literal: true

class Email < ActiveResourceModel
  self.collection_name = 'email/emails'
  self.service = :email

  %w[opened delivered clicked bounced dropped].each do |event|
    define_method "#{event}?" do
      email_tracking_events.any? { |e| e.event == event }
    end
  end

  def status
    return 'delivered' if delivered?
    return 'failed' if dropped?

    'pending'
  end
end
