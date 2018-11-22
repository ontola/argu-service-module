# frozen_string_literal: true

module Updateable
  module Controller
    extend ActiveSupport::Concern

    included do
      active_response :update, :edit
    end
  end
end
