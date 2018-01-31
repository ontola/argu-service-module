# frozen_string_literal: true

module UriTemplateHelper
  def expand_uri_template(template, args = {})
    tmpl = uri_template(template)
    raise "Uri template #{template} is missing" unless tmpl
    args[:parent_iri] = split_iri_segments(args[:parent_iri]) if args[:parent_iri].present?
    args[:collection_iri] = split_iri_segments(args[:collection_iri]) if args[:collection_iri].present?
    args[:only_path] ? tmpl.expand(args) : "https://#{Rails.application.config.host_name}#{tmpl.expand(args)}"
  end

  def uri_template(template)
    Rails.application.config.uri_templates[template]
  end

  def split_iri_segments(iri)
    iri.to_s.split('/').map(&:presence).compact
  end
end
