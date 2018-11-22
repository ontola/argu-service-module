# frozen_string_literal: true

module Updateable
  module Action
    extend ActiveSupport::Concern

    included do
      define_action(
        :update,
        description: -> { update_description },
        type: NS::SCHEMA[:UpdateAction],
        policy: :update?,
        label: -> { update_label },
        image: 'fa-pencil-square-o',
        url: -> { update_url },
        http_method: :put,
        form: -> { "#{resource.class}Form".safe_constantize },
        iri_template: :edit_iri,
        iri_template_opts: -> { update_template_opts }
      )
    end

    def update_description; end

    def update_label; end

    def update_template_opts
      {}
    end

    def update_url
      resource.iri
    end
  end
end
