# frozen_string_literal: true

require 'oauth2'
require 'json_api_collection_parser'
require 'json_api_resource_parser'

class ActiveResourceModel < ActiveResource::Base
  self.collection_parser = JsonApiCollectionParser
  self.include_format_in_path = false
  self.site = Rails.configuration.oauth_url
  headers[:headers] = {'Accept' => 'application/vnd.api+json'}

  def self.instantiate_record(record, prefix_options = {})
    super(JsonApiResourceParser.new(record).parse, prefix_options)
  end

  def self.argu_client
    @argu_client ||= OAuth2::Client.new(
      ENV['ARGU_APP_ID'],
      ENV['ARGU_APP_SECRET'],
      site: ENV['OAUTH_URL']
    )
  end

  def self.connection
    @service_token ||= OAuth2::AccessToken.new(argu_client, ENV['SERVICE_TOKEN'])
  end
end
