# frozen_string_literal: true

class ApplicationForm < LinkedRails::Form
  extend URITemplateHelper

  class << self
    def form_iri_path
      RDF::URI(
        [
          '',
          Rails.application.config.try(:iri_suffix),
          :forms,
          to_s.sub('Form', '').tableize
        ].compact.join('/')
      )
    end

    def form_options_iri(attr)
      lambda do
        LinkedRails.iri(path: [
          '',
          Rails.application.config.try(:iri_suffix),
          :enums,
          model_class.to_s.tableize,
          attr
        ].compact.join('/'))
      end
    end

    private

    def actor_selector(attr = :creator)
      field attr,
            datatype: NS.xsd.string,
            max_count: 1,
            min_count: 1,
            sh_in: -> { actors_iri }
    end
  end
end
