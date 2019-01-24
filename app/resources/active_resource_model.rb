# frozen_string_literal: true

require 'oauth2'
require 'json_api_collection_parser'
require 'json_api_resource_parser'

class ActiveResourceModel < ActiveResource::Base
  extend ServiceHelper
  class_attribute :service_name

  self.collection_parser = JsonApiCollectionParser
  self.include_format_in_path = false
  self.site = ''
  self.service_name = :argu
  headers['Accept'] = 'application/vnd.api+json'

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
    protected

    def connection(_refresh = false)
      @service_token ||= OauthConnection.new(service(service_name, token: ENV['SERVICE_TOKEN']))
    end

    def headers
      headers = super
      headers['X-Forwarded-Host'] ||= Rails.application.config.host_name
      headers
    end
  end

  class OauthConnection
    def initialize(token)
      @token = token
    end

    def get(path, headers = {})
      @token.get(relative_path(path), headers: headers)
    end

    def delete(path, headers = {})
      @token.delete(relative_path(path), headers: headers)
    end

    def patch(path, body = '', headers = {})
      @token.patch(
        relative_path(path),
        body: body,
        headers: headers.merge('Content-Type': ActiveResource::Formats[:json].mime_type)
      )
    end

    def put(path, body = '', headers = {})
      @token.put(
        relative_path(path),
        body: body,
        headers: headers.merge('Content-Type': ActiveResource::Formats[:json].mime_type)
      )
    end

    def post(path, body = '', headers = {})
      @token.post(
        relative_path(path),
        body: body,
        headers: headers.merge('Content-Type': ActiveResource::Formats[:json].mime_type)
      )
    end

    private

    def relative_path(path)
      path = URI(path)
      path.scheme = nil
      path.host = nil
      path.port = nil
      path
    end
  end
end
