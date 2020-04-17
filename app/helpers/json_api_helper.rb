# frozen_string_literal: true

module JsonAPIHelper
  # @param [Integer] status HTTP response code
  # @param [Array<Hash, String>] errors A list of errors
  # @return [Hash] JSONAPI error hash to use in a render method
  def json_api_error(status, errors = nil)
    {
      json: {
        errors: json_api_formatted_errors(errors, Rack::Utils::HTTP_STATUS_CODES[status])
      },
      status: status
    }
  end

  def json_api_formatted_errors(errors, status)
    case errors
    when Array
      errors.map { |error| json_api_formatted_errors(error, status) }.flatten
    when ActiveModel::Errors
      json_api_formatted_model_errors(errors, status)
    when Hash
      [errors.merge(status: status)]
    else
      [{status: status, message: errors.is_a?(String) ? errors : nil}]
    end
  end

  def json_api_formatted_model_errors(errors, status)
    errors.keys.reduce([]) do |array, key|
      array.concat(
        errors.full_messages_for(key).map.with_index do |m, i|
          {code: "value_#{errors.details[key][i][:error]}".upcase, message: m, status: status, source: {parameter: key}}
        end
      )
    end
  end

  # @param [Hash] json_api_response The full json_api response
  # @param [Hash] resource A hash containing the id and type to look for
  # @return [HashWithIndifferentAccess, nil] The included resource or nil when not found
  def json_api_included_resource(json_api_response, resource)
    resource = resource.with_indifferent_access
    json_api_response.with_indifferent_access['included']
      &.find { |r| r[:id] == resource[:id] && (resource[:type].nil? || r[:type] == resource[:type]) }
  end

  # The params, deserialized when format is json_api method is not safe
  # @example Resource params from json_api request
  #   params = {
  #     data: {type: 'motions', attributes: {body: 'body'}},
  #     relationships: {relation: {data: {type: 'motions', id: motion.id}}}
  #   }
  #   params # => {motion: {body: 'body', relation_type: 'motions', relation_id: 1}}
  # @example Resource params from LD request
  # @return [Hash] The params
  def json_api_params(params)
    raise ActionController::UnpermittedParameters.new(%w[type]) if json_api_wrong_type(params)
    raise ActionController::ParameterMissing.new(:attributes) if params['data']['attributes'].blank?

    json_api_to_action_parameters(params)
  end

  # Extracted from active_model_serializers
  def json_api_parse!(document, options = {})
    json_api_parse(document, options) do |invalid_payload, reason|
      raise UnpermittedParameters.new("Invalid payload (#{reason}): #{invalid_payload}")
    end
  end

  # Same as parse!, but returns an empty hash instead of raising on invalid payloads.
  def json_api_parse(document, options = {}) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    document = document.dup.permit!.to_h if document.is_a?(ActionController::Parameters)

    json_api_validate_payload(document) do |invalid_document, reason|
      yield invalid_document, reason if block_given?
      return {}
    end

    primary_data = document['data']
    attributes = primary_data['attributes'] || {}
    attributes['id'] = primary_data['id'] if primary_data['id']
    relationships = primary_data['relationships'] || {}

    json_api_filter_fields(attributes, options)
    json_api_filter_fields(relationships, options)

    hash = {}
    hash.merge!(json_api_parse_attributes(attributes, options))
    hash.merge!(json_api_parse_relationships(relationships, options))

    hash
  end

  def parse_json_api_params?(params)
    request.format.json_api? && params[:data].present?
  end

  private

  # Checks whether a payload is compliant with the JSON API spec.
  #
  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def json_api_validate_payload(payload) # rubocop:disable Metrics/MethodLength
    unless payload.is_a?(Hash)
      yield payload, 'Expected hash'
      return
    end

    primary_data = payload['data']
    unless primary_data.is_a?(Hash)
      yield payload, {data: 'Expected hash'}
      return
    end

    attributes = primary_data['attributes'] || {}
    unless attributes.is_a?(Hash)
      yield payload, {data: {attributes: 'Expected hash or nil'}}
      return
    end

    relationships = primary_data['relationships'] || {}
    unless relationships.is_a?(Hash)
      yield payload, {data: {relationships: 'Expected hash or nil'}}
      return
    end

    relationships.each do |(key, value)|
      unless value.is_a?(Hash) && value.key?('data')
        yield payload, {data: {relationships: {key => 'Expected hash with :data key'}}}
      end
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def json_api_filter_fields(fields, options)
    if (only = options[:only])
      fields.slice!(*Array(only).map(&:to_s))
    elsif (except = options[:except])
      fields.except!(*Array(except).map(&:to_s))
    end
  end

  def json_api_field_key(field, options)
    (options[:keys] || {}).fetch(field.to_sym, field).to_sym
  end

  def json_api_parse_attributes(attributes, options)
    attributes
      .map { |(k, v)| {json_api_field_key(k, options) => v} }
      .reduce({}, :merge)
  end

  # Given an association name, and a relationship data attribute, build a hash
  # mapping the corresponding ActiveRecord attribute to the corresponding value.
  #
  # @example
  #   parse_relationship(:comments, [{ 'id' => '1', 'type' => 'comments' },
  #                                  { 'id' => '2', 'type' => 'comments' }],
  #                                 {})
  #    # => { :comment_ids => ['1', '2'] }
  #   parse_relationship(:author, { 'id' => '1', 'type' => 'users' }, {})
  #    # => { :author_id => '1' }
  #   parse_relationship(:author, nil, {})
  #    # => { :author_id => nil }
  # @param [Symbol] assoc_name
  # @param [Hash] assoc_data
  # @param [Hash] options
  # @return [Hash{Symbol, Object}]
  def json_api_parse_relationship(assoc_name, assoc_data, options) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    prefix_key = field_key(assoc_name, options).to_s.singularize
    hash =
      if assoc_data.is_a?(Array)
        {"#{prefix_key}_ids".to_sym => assoc_data.map { |ri| ri['id'] }}
      else
        {"#{prefix_key}_id".to_sym => assoc_data ? assoc_data['id'] : nil}
      end

    polymorphic = (options[:polymorphic] || []).include?(assoc_name.to_sym)
    if polymorphic
      hash["#{prefix_key}_type".to_sym] = assoc_data.present? ? assoc_data['type'].classify : nil
    end

    hash
  end

  def json_api_parse_relationships(relationships, options)
    relationships
      .map { |(k, v)| parse_relationship(k, v['data'], options) }
      .reduce({}, :merge)
  end

  def json_api_to_action_parameters(params)
    ActionController::Parameters.new(
      params.to_unsafe_h.merge(
        params.require(:data).require(:type).singularize.underscore =>
          json_api_parse!(params, deserialize_params_options)
      )
    )
  end

  def json_api_wrong_type(params)
    params['data']['type'].present? && params['data']['type'] != controller_name.camelcase(:lower)
  end
end
