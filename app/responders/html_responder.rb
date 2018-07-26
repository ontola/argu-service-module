# frozen_string_literal: true

require 'active_response/responders/html'

class HTMLResponder < ActiveResponse::Responders::HTML
  respond_to :html
end
