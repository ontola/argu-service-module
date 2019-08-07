# frozen_string_literal: true

class ApplicationForm < LinkedRails::Form
  include UriTemplateHelper

  class << self
    private

    def actor_selector
      {
        custom: true,
        datatype: NS::XSD[:string],
        default_value: -> { user_context.user.iri },
        max_count: 1,
        sh_in: -> { actors_iri(target.root) }
      }
    end
  end
end
