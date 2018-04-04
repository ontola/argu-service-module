# frozen_string_literal: true

module JsonApiHelper
  # @param [Integer] status HTTP response code
  # @param [Array<Hash, String>] errors A list of errors
  # @return [Hash] JSONApi error hash to use in a render method
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

  def json_api_params(params)
    raise ActionController::UnpermittedParameters.new(%w[type]) if json_api_wrong_type(params)
    raise ActionController::ParameterMissing.new(:attributes) if params['data']['attributes'].blank?
    json_api_to_action_parameters(params)
  end

  private

  def json_api_to_action_parameters(params)
    ActionController::Parameters.new(
      params.to_unsafe_h.merge(
        params.require(:data).require(:type).singularize.underscore =>
          ActiveModelSerializers::Deserialization.jsonapi_parse!(params, deserialize_params_options)
      )
    )
  end

  def json_api_wrong_type(params)
    params['data']['type'].present? && params['data']['type'] != controller_name.camelcase(:lower)
  end
end
