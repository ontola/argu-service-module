# frozen_string_literal: true

require 'oauth2'
require 'json_api_collection_parser'
require 'json_api_resource_parser'

class ActiveResourceModel < ActiveResource::Base
  extend ServiceHelper
  self.collection_parser = JsonApiCollectionParser
  self.include_format_in_path = false
  self.auth_type = :bearer
  self.bearer_token = ENV['SERVICE_TOKEN']
  headers['Accept'] = 'application/vnd.api+json'
  headers['X-Forwarded-Proto'] = 'https'

  class_attribute :service, default: :argu

  def build_child(klass, opts = {})
    ChildHelper.child_instance(self, klass, opts)
  end

  def load(attributes, remove_root = false, persisted = false)
    attributes = JsonApiResourceParser.new(attributes).parse if (attributes.keys & %w[data attributes]).any?
    super
  end

  protected

  def id_from_response(response); end

  def load_attributes_from_response(response)
    return unless load_attributes_from_response?(response)

    load(self.class.format.decode(response.body), true, true)
    @persisted = true
  end

  private

  def find_or_create_resource_for(name)
    resource = super
    resource < ActiveRecord::Base ? create_resource_for(name.to_s.camelize) : resource
  end

  def load_attributes_from_response?(response)
    response_code_allows_body?(response.status.to_i) && response.body.present?
  end

  class << self
    def attributes_for_new(_opts)
      {}
    end

    def build_new(opts = {})
      ChildHelper.child_instance(opts[:collection].try(:parent), self, opts)
    end

    def connection(refresh = false)
      con = super
      con.site = site
      con
    end

    def prefix(_options = {})
      site.path.ends_with?('/') ? site.path : "#{site.path}/"
    end

    def prefix_source
      prefix
    end

    def site
      URI("#{service_url(service)}/#{ActsAsTenant.current_tenant&.tenant&.path}")
    end

    def headers
      super.merge('X-Forwarded-Host' => ActsAsTenant.current_tenant.tenant.host)
    end
  end
end
