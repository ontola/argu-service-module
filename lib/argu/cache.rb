# frozen_string_literal: true

module Argu
  class Cache
    include SerializationHelper
    attr_accessor :adapter_opts, :directory, :format, :resource, :timestamp

    def initialize(opts = {})
      self.directory = opts[:directory] || ENV['CACHE_DIRECTORY']
    end

    def write(resource, format, adapter_opts = {})
      self.resource = resource
      self.adapter_opts = adapter_opts
      self.format = format
      self.timestamp = Time.current.strftime('%Y%m%dT%H%M')

      write_cache if cache_resource?
    end

    private

    def serializer(opts)
      serializable_resource(
        resource,
        %w[guest cache],
        {include: resource.class.try(:preview_includes)}.merge(opts)
      )
    end

    def cache_resource?
      directory.present?
    end

    def create_symlink
      File.symlink(current_dir, latest_dir)
    rescue Errno::EEXIST
      nil
    end

    def current_dir
      storage_dir(timestamp)
    end

    def data(format, adapter_opts)
      ActsAsTenant.with_tenant(ActsAsTenant.current_tenant || resource.try(:root)) do
        adapter_for_type = serializer(adapter_opts)
        if format == :json
          Oj.dump(adapter_for_type.serializable_hash[:data][:attributes], mode: :compat)
        else
          adapter_for_type.dump(format)
        end
      end
    end

    def delete_latest_dir
      File.delete(latest_dir) if File.symlink?(latest_dir)
    rescue Errno::ENOENT
      nil
    end

    def file_name(format)
      "#{current_dir}/index.#{format}"
    end

    def latest_dir
      storage_dir(:latest)
    end

    def storage_dir(version)
      "#{directory}/latest/#{Digest::MD5.hexdigest(resource.iri).scan(/.{,8}/).join('/')}#{version}"
    end

    def write_cache
      FileUtils.mkdir_p current_dir

      write_file(format, adapter_opts)

      delete_latest_dir
      create_symlink

      Rails.logger.info "Written to #{file_name(format)}"
      file_name(format)
    end

    def write_file(format, adapter_opts)
      File.open(file_name(format), 'w') { |file| file.write(data(format, adapter_opts)) }
    end
  end
end
