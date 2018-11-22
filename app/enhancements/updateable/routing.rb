# frozen_string_literal: true

module Updateable
  module Routing
    class << self
      def route_concerns(mapper)
        mapper.concern :updateable do
          mapper.member do
            mapper.get :edit
            mapper.patch :update
            mapper.put   :update
          end
        end
      end
    end
  end
end
