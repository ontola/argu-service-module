# frozen_string_literal: true

module IRITemplateHelper
  extend ActiveSupport::Concern

  include UriTemplateHelper

  def iri_template
    uri_template(iri_template_name) || super
  end

  def iri_template_name
    "#{model_name.route_key}_iri"
  end

  def reload(**_opts)
    @iri = nil
    super
  end
end
