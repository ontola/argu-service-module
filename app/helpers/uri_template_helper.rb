# frozen_string_literal: true

module UriTemplateHelper
  URI_TEMPLATES =
    Hash[
      YAML.safe_load(File.read(Rails.root.join('config', 'uri_templates.yml')))
        .map { |k, v| [k, URITemplate.new(v)] }
    ].with_indifferent_access.freeze

  def expand_uri_template(template, args = {})
    tmpl = uri_template(template)
    raise "Uri template #{template} is missing" unless tmpl
    args[:parent_iri] = split_iri_segments(args[:parent_iri]) if args[:parent_iri].present?
    args[:only_path] ? tmpl.expand(args) : "https://#{Rails.application.config.host_name}#{tmpl.expand(args)}"
  end

  def uri_template(template)
    URI_TEMPLATES[template]
  end

  def split_iri_segments(iri)
    iri.to_s.split('/').map(&:presence).compact
  end
end
