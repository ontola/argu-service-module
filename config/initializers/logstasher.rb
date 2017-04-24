# frozen_string_literal: true
if LogStasher.enabled
  LogStasher.add_custom_fields do |fields|
    # This block is run in application_controller context,
    # so you have access to all controller methods
    fields[:environment] = Rails.env
    fields[:user] = try(:current_user)&.url
    fields[:user_id] = try(:current_user)&.id
    fields[:profile] = try(:current_profile)&.url
    fields[:profile_id] = try(:current_profile)&.id
    fields[:ua] = request.env['HTTP_USER_AGENT']
    fields[:a_params] = request.try(:params).try(:slice, 'r', 'q')
  end
end
