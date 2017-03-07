# frozen_string_literal: true
require 'oauth2'

class ActiveResourceModel < ActiveResource::Base
  extend JsonApiHelper

  self.include_format_in_path = false
  self.site = Rails.configuration.oauth_url
  headers[:headers] = {'Accept' => 'application/vnd.api+json'}

  def self.instantiate_record(record, prefix_options = {})
    super(parse_record(record, record['data'] || record), prefix_options)
  end

  def self.argu_client
    @argu_client ||= OAuth2::Client.new(
      ENV['ARGU_APP_ID'],
      ENV['ARGU_APP_SECRET'],
      site: ENV['OAUTH_URL']
    )
  end

  def self.connection
    @argu_token ||= OAuth2::AccessToken.new(argu_client, ENV['CLIENT_TOKEN'])
  end

  def self.parse_record(body, record)
    return if record.nil?
    record = json_api_included_resource(body, record) || record
    parsed_attributes(record)
      .merge(parsed_relationships(body, record))
      .transform_keys { |key| key.to_s.underscore }
  end

  def self.parsed_attributes(record)
    {
      'id' => record['id'],
      'type' => record['type']
    }.merge(record['attributes']&.select { |key, _value| key[0] != '@' } || {})
  end

  def self.parsed_relationships(body, record)
    a = record['relationships']&.map do |key, value|
      relationship = if value['data'].is_a?(Hash)
                       parse_record(body, value['data'])
                     else
                       value['data']&.map { |r| parse_record(body, r) }
                     end
      [key, relationship]
    end
    Hash[a || {}]
  end
end
