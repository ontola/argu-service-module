# frozen_string_literal: true

module Actionable
  module Model
    extend ActiveSupport::Concern

    def actions(user_context)
      @actions ||= self.class.actions_class!.new(resource: self, user_context: user_context).actions
    end

    def action(user_context, tag)
      actions(user_context).find { |a| a.tag == tag }
    end
  end
end
