# frozen_string_literal: true

class BroadcastWorker
  include Sidekiq::Worker

  attr_accessor :data_event

  def perform(attrs = {})
    attrs = attrs.with_indifferent_access
    attrs[:resource] = attrs[:resource_type].classify.constantize.find(attrs[:resource_id])
    attrs[:resource_id] = attrs[:resource].iri if attrs[:resource].respond_to?(:iri)

    self.data_event = data_event_from_attrs(attrs)

    write_nquads
    publish_data_event
  end

  def resource=(resource)
    self.data_event = data_event_from_attrs(resource: resource)
  end

  def write_nquads
    return unless cache_resource?

    timestamp = Time.current.strftime('%Y%m%dT%H%M')
    current_dir = storage_dir(timestamp)

    FileUtils.mkdir_p current_dir

    File.open(file_name(timestamp), 'w') { |file| file.write(data_event.nquads) }

    latest_dir = storage_dir(:latest)
    File.delete(latest_dir) if File.symlink?(latest_dir)
    File.symlink(current_dir, latest_dir)
  end

  private

  def cache_resource?
    ENV['CACHE_DIRECTORY'] && resource.cache_nquads
  end

  def data_event_from_attrs(attrs)
    DataEvent.new(attrs)
  end

  def file_name(version)
    "#{storage_dir(version)}/index.nq"
  end

  def publish_data_event
    data_event.publish
  end

  def resource
    data_event.resource
  end

  def storage_dir(version)
    "#{ENV['CACHE_DIRECTORY']}/latest/#{Digest::MD5.hexdigest(resource.iri).scan(/.{,8}/).join('/')}#{version}"
  end
end
