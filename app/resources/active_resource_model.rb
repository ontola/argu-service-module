# frozen_string_literal: true

require 'oauth2'
require 'json_api_collection_parser'
require 'json_api_resource_parser'

class ActiveResourceModel < ActiveResource::Base
  extend ServiceHelper
  self.collection_parser = JsonApiCollectionParser
  self.include_format_in_path = false
  self.site = URI("#{service_url(:argu)}/:root_id")
  self.auth_type = :bearer
  self.bearer_token = ENV['SERVICE_TOKEN']
  headers['Accept'] = 'application/vnd.api+json'
  headers['X-Forwarded-Host'] = Rails.application.config.host_name

  def load(attributes, remove_root = false, persisted = false)
    attributes = JsonApiResourceParser.new(attributes).parse if (attributes.keys & %w[data attributes]).any?
    super
  end

  def root_id
    prefix_options[:root_id] || ActsAsTenant.current_tenant.uuid
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
end
