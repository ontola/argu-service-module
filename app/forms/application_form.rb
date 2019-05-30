# frozen_string_literal: true

class ApplicationForm < LinkedRails::Form
  extend UriTemplateHelper

  class << self
    private

    def actor_selector
      {
        custom: true,
        datatype: NS::XSD[:string],
        default_value: ->(resource) { resource.form.user_context.user.iri },
        max_count: 1,
        sh_in: ->(resource) { actors_iri(resource.form.target.root) }
      }
    end
  end
end
