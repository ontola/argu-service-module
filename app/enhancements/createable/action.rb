# frozen_string_literal: true

module Createable
  module Action
    extend ActiveSupport::Concern

    included do
      include Pundit

      define_action(
        :create,
        description: -> { create_description },
        result: -> { result_class },
        type: -> { [NS::ARGU["Create::#{result_class}"], NS::SCHEMA[:CreateAction]] },
        policy: -> { create_policy },
        label: -> { new_label },
        image: -> { new_image },
        url: -> { create_url(resource) },
        http_method: :post,
        collection: -> { create_on_collection? },
        form: -> { "#{result_class}Form".safe_constantize },
        iri_template: :new_iri,
        submit_label: -> { submit_label },
        favorite: -> { create_action_favorite }
      )
    end

    private

    def association
      @association ||= result_class.to_s.tableize
    end

    def create_description; end

    def create_on_collection?
      true
    end

    def create_policy
      :create_child?
    end

    def create_url(resource)
      resource.iri
    end

    def create_action_favorite
      association.to_sym == :votes
    end

    def new_image
      'fa-plus'
    end

    def new_label
      I18n.t("#{association}.type_new")
    end

    def result_class
      create_on_collection? ? resource.association_class : self.class.name.gsub('Actions', '').constantize
    end

    def submit_label; end
  end
end
