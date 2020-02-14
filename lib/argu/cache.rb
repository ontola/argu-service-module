# frozen_string_literal: true

module Argu
  class Cache
    include SerializationHelper
    attr_accessor :adapter_opts, :adapter_type, :directory, :format, :resource, :timestamp, :user_context

    def initialize(opts = {})
      self.user_context = create_user_context(%w[guest cache])
      self.directory = opts[:directory] || ENV['CACHE_DIRECTORY']
    end

    def write(resource, adapter_type, format, adapter_opts = {})
      self.resource = resource
      self.adapter_opts = adapter_opts
      self.adapter_type = adapter_type
      self.format = format
      self.timestamp = Time.current.strftime('%Y%m%dT%H%M')

      write_cache if cache_resource?
    end

    private

    def adapter(adapter_type, opts)
      serializable_resource(
        adapter_type,
        resource,
        nil,
        {include: resource.class.try(:preview_includes), scope: user_context}.merge(opts)
      ).adapter
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

    def data(adapter_type, format, adapter_opts)
      ActsAsTenant.with_tenant(ActsAsTenant.current_tenant || resource.try(:root)) do
        adapter_for_type = adapter(adapter_type, adapter_opts)
        if adapter_type == :hex_adapter
          adapter_for_type.dump
        elsif adapter_type == :rdf
          adapter_for_type.dump(RDF::Format.for(file_extension: format).symbols.first)
        else
          adapter_for_type.to_json
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

      write_file(adapter_type, format, adapter_opts)

      delete_latest_dir
      create_symlink

      Rails.logger.info "Written to #{file_name(format)}"
      file_name(format)
    end

    def write_file(adapter_type, format, adapter_opts)
      File.open(file_name(format), 'w') { |file| file.write(data(adapter_type, format, adapter_opts)) }
    end
  end
end
