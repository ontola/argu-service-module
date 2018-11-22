# frozen_string_literal: true

module Actionable
  module Routing
    class << self
      def route_concerns(mapper)
        mapper.concern :actionable do
          mapper.resources :action_items, path: 'actions', only: %i[index show]
        end
      end
    end
  end
end
