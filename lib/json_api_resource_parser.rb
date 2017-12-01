# frozen_string_literal: true

class JsonApiResourceParser
  include JsonApiHelper

  def initialize(body)
    @body = body
    @record = body['data'] || body
    @parsed_records = {}
  end

  def parse
    parse_record(@record)
  end

  private

  def parse_record(record)
    return if record.nil?
    identifier = "#{record['type']}_#{record['id']}"
    return @parsed_records[identifier] if @parsed_records.key?(identifier)
    parsed_record = json_api_included_resource(@body, record) || record
    # Store a temporary representation of the record to prevent a
    # recursive loop when parsing the relationship in the next line
    @parsed_records[identifier] = parsed_record
    @parsed_records[identifier] =
      parsed_attributes(parsed_record)
        .merge(parsed_relationships(parsed_record))
        .transform_keys { |key| key.to_s.underscore }
  end

  def parsed_attributes(record)
    {
      'id' => record['id'],
      'type' => record['type']
    }.merge(record['attributes']&.select { |key, _value| key[0] != '@' } || {})
  end

  def parsed_relationships(record)
    relationships = record['relationships']&.map do |key, value|
      relationship = if value['data'].is_a?(Hash)
                       parse_record(value['data'])
                     else
                       value['data']&.map { |r| parse_record(r) }
                     end
      [key, relationship]
    end
    Hash[relationships || {}]
  end
end
