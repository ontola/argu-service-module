# frozen_string_literal: true

module Createable
  module Controller
    extend ActiveSupport::Concern

    included do
      active_response :new, :create
    end
  end
end
