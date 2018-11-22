# frozen_string_literal: true

module Destroyable
  module Routing
    class << self
      def route_concerns(mapper)
        mapper.concern :destroyable do
          mapper.member do
            mapper.get :delete, action: :delete, as: :delete
            mapper.delete '', action: :destroy, as: :destroy
          end
        end
      end
    end
  end
end
