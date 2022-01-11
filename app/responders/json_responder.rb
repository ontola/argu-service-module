# frozen_string_literal: true

require 'active_response/responders/json'

class JsonResponder < ActiveResponse::Responders::JSON
  respond_to :json
end
