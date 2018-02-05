# frozen_string_literal: true

module UriTemplateHelper
  def expand_uri_template(template, args = {})
    tmpl = uri_template(template)
    raise "Uri template #{template} is missing" unless tmpl
    args[:parent_iri] = split_iri_segments(args[:parent_iri]) if args[:parent_iri].present?
    args[:collection_iri] = split_iri_segments(args[:collection_iri]) if args[:collection_iri].present?
    path = tmpl.expand(args)
    args[:only_path] ? path : path_with_hostname(path)
  end

  def path_with_hostname(path)
    "#{Rails.application.config.origin}#{path}"
  end

  def split_iri_segments(iri)
    iri.to_s.split('/').map(&:presence).compact
  end

  def uri_template(template)
    Rails.application.config.uri_templates[template]
  end
end
