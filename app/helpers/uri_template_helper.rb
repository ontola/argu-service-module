# frozen_string_literal: true

module UriTemplateHelper
  # @return [RDF::URI]
  def collection_iri(parent, type, opts = {})
    canonical = opts.delete(:canonical)
    RDF::URI(
      expand_uri_template(
        "#{type}_collection_#{canonical ? 'canonical' : 'iri'}",
        opts.merge(parent_iri: parent.try(:iri_path) || parent)
      )
    )
  end

  # @return [String]
  def collection_iri_path(parent, type, opts = {})
    collection_iri(parent, type, opts.merge(only_path: true)).to_s
  end

  # @return [String]
  def expand_uri_template(template, args = {})
    tmpl = uri_template(template)
    raise "Uri template #{template} is missing" unless tmpl
    args[:parent_iri] = split_iri_segments(args[:parent_iri]) if args[:parent_iri].present?
    args[:collection_iri] = split_iri_segments(args[:collection_iri]) if args[:collection_iri].present?
    path = tmpl.expand(args)
    args[:only_path] ? path : path_with_hostname(path)
  end

  def link_to(name = nil, options = nil, html_options = nil, &block)
    name = name.try(:iri_path) || name
    options = options.try(:iri_path) || options
    super
  end

  # @return [String]
  def path_with_hostname(path)
    "#{Rails.application.config.origin}#{path}"
  end

  def root_iri(opts = {})
    RDF::URI(opts[:only_path] ? '' : Rails.application.config.origin)
  end

  # @return [Array<String>]
  def split_iri_segments(iri)
    iri.to_s.split('/').map(&:presence).compact
  end

  # @return [URITemplat]
  def uri_template(template)
    Rails.application.config.uri_templates[template]
  end

  # @return [RDF::URI]
  def new_iri(parent, collection = nil, opts = {})
    query = opts.delete(:query)
    iri = parent.is_a?(String) ? parent : collection_iri_path(parent, collection, opts)
    uri = RDF::URI(expand_uri_template(:new_iri, opts.merge(parent_iri: iri)))
    uri.query = query.to_param if query
    uri
  end

  # @return [String]
  def new_iri_path(parent, collection = nil, opts = {})
    new_iri(parent, collection, opts.merge(only_path: true)).to_s
  end

  %i[edit delete trash untrash move settings statistics feeds conversions invites export logs].each do |method|
    # @return [RDF::URI]
    define_method "#{method}_iri" do |parent, opts = {}|
      iri = parent.try(:iri_path) || parent
      opts[:parent_iri] ||= iri if iri
      RDF::URI(expand_uri_template("#{method}_iri", opts))
    end

    # @return [String]
    define_method "#{method}_iri_path" do |parent, opts = {}|
      send("#{method}_iri", parent, opts.merge(only_path: true)).to_s
    end
  end
end
