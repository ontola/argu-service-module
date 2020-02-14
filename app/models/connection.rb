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

  private

  def with_channel
    connection.with_channel { |c| yield c }
  end

  class << self
    def process_event(delivery_info, body)
      puts " [x] #{delivery_info.delivery_tag}:#{JSON.parse(body)}"
      ActiveRecord::Base.connection.reconnect! unless ActiveRecord::Base.connection.active?
      DataEvent.parse(body)
    end

    def publish(name, body)
      new.publish(name, body)
      body
    end

    def subscribe(queue_name, &block)
      channel, queue = subscribe_to_queue(queue_name)
      begin
        listen(channel, queue, &block)
      rescue Interrupt
        connection.close
      end
    end

    def subscribe_to_queue(queue)
      channel = new.connection.create_channel
      channel.on_uncaught_exception do |e, _consumer|
        puts "error: #{e}"
        Bugsnag.notify(e) { |report| add_rabbit_mq_info(report) }
      end
      x = channel.fanout('events', durable: true)
      q = channel.queue(queue, durable: true)
      q.bind(x)
      [channel, q]
    end

    private

    def add_rabbit_mq_info(report)
      report.add_tab(
        :rabbitmq,
        delivery_info: @delivery_info.to_s,
        properties: @properties,
        body: @body
      )
    end

    def listen(channel, queue)
      puts ' [*] Waiting for events. To exit press CTRL+C'

      queue.subscribe(manual_ack: true, block: true) do |delivery_info, properties, body|
        @delivery_info = delivery_info
        @properties = properties
        @body = body
        yield process_event(delivery_info, body)
        channel.ack(delivery_info.delivery_tag)
      end
    end
  end
end
