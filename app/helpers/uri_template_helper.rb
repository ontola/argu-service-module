# frozen_string_literal: true

module UriTemplateHelper
  # @return [RDF::URI]
  def actors_iri(parent)
    iri_from_template(:actors_iri, parent_iri: parent.iri_path)
  end

  # @return [RDF::URI]
  def collection_iri(parent, type, opts = {})
    RDF::DynamicURI(path_with_hostname(collection_iri_path(parent, type, opts)))
  end

  # @return [String]
  def collection_iri_path(parent, type, opts = {})
    canonical = opts.delete(:canonical) && uri_template("#{type}_collection_canonical")
    expand_uri_template(
      "#{type}_collection_#{canonical ? 'canonical' : 'iri'}",
      opts.merge(parent_iri: (parent.try(:iri_path) || parent).presence)
    )
  end

  # @return [String]
  def expand_uri_template(template, args = {})
    tmpl = uri_template(template)
    raise "Uri template #{template} is missing" unless tmpl
    args[:parent_iri] = split_iri_segments(args[:parent_iri])
    args[:collection_iri] = split_iri_segments(args[:collection_iri]) if args[:collection_iri].present?
    path = tmpl.expand(args)
    args[:with_hostname] ? path_with_hostname(path) : path
  end

  def iri_from_template(template, opts = {})
    RDF::DynamicURI(expand_uri_template(template, opts.merge(with_hostname: true)))
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

  # @return [Array<String>]
  def split_iri_segments(iri)
    return if iri.blank?
    iri.to_s.split('/').map(&:presence).compact.presence
  end

  # @return [URITemplat]
  def uri_template(template)
    Rails.application.config.uri_templates[template]
  end

  # @return [RDF::URI]
  def new_iri(parent, collection = nil, opts = {})
    RDF::DynamicURI(path_with_hostname(new_iri_path(parent, collection, opts)))
  end

  # @return [String]
  def new_iri_path(parent, collection = nil, opts = {})
    query = opts.delete(:query)
    iri = parent.is_a?(String) ? parent : collection_iri_path(parent, collection, opts)
    uri = URI(expand_uri_template(:new_iri, opts.merge(parent_iri: iri)))
    uri.query = query.to_param if query
    uri.to_s
  end

  %i[edit delete trash untrash settings statistics feeds conversions invites export logs].each do |method|
    # @return [RDF::URI]
    define_method "#{method}_iri" do |parent, opts = {}|
      RDF::DynamicURI(path_with_hostname(send("#{method}_iri_path", parent, opts)))
    end

    # @return [String]
    define_method "#{method}_iri_path" do |parent, opts = {}|
      iri = parent.try(:iri_path) || parent
      opts[:parent_iri] ||= iri if iri.present?
      opts[:only_path] = true
      expand_uri_template("#{method}_iri", opts)
    end
  end
end
