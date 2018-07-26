# frozen_string_literal: true

require 'active_response/responders/json_api'

class JsonApiResponder < ActiveResponse::Responders::JsonApi
  respond_to :json_api

  def updated_resource(**_opts)
    controller.head :no_content
  end
end
