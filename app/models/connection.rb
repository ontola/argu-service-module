# frozen_string_literal: true

require 'bunny'

class Connection
  @connection = nil

  def connection
    return @connection if @connection&.open?
    connection = Bunny.new
    connection.start
    @connection = connection
  end

  # @param [String] name The name of the channel to publish to
  # @param [String] body The string to publish
  def publish(name, body)
    return if Rails.env.test?
    with_channel do |channel|
      channel
        .fanout(name, durable: true)
        .publish(body, persistent: true)
    end
    connection.close
  end

  def self.publish(name, body)
    new.publish(name, body)
    body
  end

  def self.subscribe(queue)
    channel, q = subscribe_to_queue(queue)
    begin
      q.subscribe(manual_ack: true, block: true) do |delivery_info, _properties, body|
        puts " [x] #{delivery_info.delivery_tag}:#{JSON.parse(body)}"
        yield DataEvent.parse(body)
        channel.ack(delivery_info.delivery_tag)
      end
    rescue Interrupt
      connection.close
    end
  end

  def self.subscribe_to_queue(queue)
    channel = new.connection.create_channel
    x = channel.fanout('events', durable: true)
    q = channel.queue(queue, durable: true)
    q.bind(x)
    puts ' [*] Waiting for events. To exit press CTRL+C'
    [channel, q]
  end

  private

  def with_channel
    connection.with_channel { |c| yield c }
  end
end
