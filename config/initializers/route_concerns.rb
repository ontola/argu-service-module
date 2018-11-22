# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      def include_route_concerns(only: nil, except: [])
        include = @scope[:controller].classify.constantize.route_concerns
        include &= only unless only.nil?
        include -= except
        concerns include
      end

      def concerns_from_enhancements
        Dir.glob("#{Rails.application.root}/app/enhancements/**{,/*/**}/routing.rb")
          .map { |path| path.split('/')[-2] }
          .reject { |mod| mod == 'enhancer' }
          .each { |mod| mod.classify.constantize.const_get(:Routing).route_concerns(self) }
      end
    end
  end
end
