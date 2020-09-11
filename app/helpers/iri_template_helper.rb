# frozen_string_literal: true

module IRITemplateHelper
  extend ActiveSupport::Concern

  include UriTemplateHelper

  def canonical_iri_template_name
    name = "#{model_name.route_key}_canonical_iri"
    name if uri_template(name).present?
  end

  def canonical_iri_template
    uri_template(canonical_iri_template_name) || iri_template
  end

  def iri_template
    uri_template(iri_template_name) || super
  end

  def iri_template_name
    "#{model_name.route_key}_iri"
  end

  def reload(_opts = {})
    @iri = nil
    super
  end
end
