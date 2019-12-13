# frozen_string_literal: true

module Argu
  class Cache
    include SerializationHelper
    attr_accessor :adapter_opts, :adapter_type, :format, :resource, :timestamp, :user_context

    def initialize
      self.user_context = create_user_context(%w[guest afe])
    end

    def write(resource, adapter_type, format, adapter_opts = {})
      self.resource = resource
      self.adapter_opts = adapter_opts
      self.adapter_type = adapter_type
      self.format = format
      self.timestamp = Time.current.strftime('%Y%m%dT%H%M') # rubocop:disable Style/FormatStringToken

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
      ENV['CACHE_DIRECTORY']
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
        if adapter_type == :rdf
          adapter(adapter_type, adapter_opts).dump(RDF::Format.for(file_extension: format).symbols.first)
        else
          adapter(adapter_type, adapter_opts).to_json
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
      "#{ENV['CACHE_DIRECTORY']}/latest/#{Digest::MD5.hexdigest(resource.iri).scan(/.{,8}/).join('/')}#{version}"
    end

    def write_cache
      FileUtils.mkdir_p current_dir

      write_file(adapter_type, format, adapter_opts)

      delete_latest_dir
      create_symlink

      Rails.logger.info "Written to #{file_name(format)}"
    end

    def write_file(adapter_type, format, adapter_opts)
      File.open(file_name(format), 'w') { |file| file.write(data(adapter_type, format, adapter_opts)) }
    end
  end
end
