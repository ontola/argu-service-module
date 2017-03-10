# frozen_string_literal: true
module UriTemplateHelper
  URI_TEMPLATES =
    Hash[YAML.load(File.read("#{Rails.root}/config/uri_templates.yml")).map { |k, v| [k, URITemplate.new(v)] }]
      .with_indifferent_access.freeze

  def expand_uri_template(template, args = {})
    if args[:path_only]
      uri_template(template).expand(args)
    else
      "https://#{Rails.application.config.host}#{uri_template(template).expand(args)}"
    end
  end

  def uri_template(template)
    URI_TEMPLATES[template]
  end
end
