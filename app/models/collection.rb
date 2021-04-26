# frozen_string_literal: true

class Collection < LinkedRails::Collection
  include Collection::CounterCache
  include IRITemplateHelper

  attr_accessor :parent_uri_template, :parent_uri_template_canonical
  attr_writer :parent_uri_template_opts

  delegate :searchable_aggregations, to: :association_class

  def action_triples
    return super unless association_class.to_s == 'Discussion'

    triples = super
    Discussion.descendants.each do |klass|
      next unless parent.respond_to?("#{klass.to_s.underscore}_collection")

      triples << RDF::Statement.new(iri, NS::ONTOLA[:createAction], iri_with_root(sanitized_action_url(klass)))
    end
    triples
  end

  def clear_total_count
    parent&.reload
    @total_count = nil
  end

  def iri(opts = {})
    return super if ActsAsTenant.current_tenant.present? || parent.blank?
    return @iri if @iri && opts.blank?

    iri = ActsAsTenant.with_tenant(parent.root) { super }
    @iri = iri if opts.blank?
    iri
  end

  def iri_opts
    opts = super
    iri_opts_add(opts, :parent_iri, split_iri_segments(parent&.iri_path))
    iri_opts_add(opts, :iri, parent&.iri_opts.try(:[], :iri))
    opts.merge(parent_uri_template_opts || {})
  end

  def search_result(opts = {})
    SearchResult.new(
      opts.merge(
        parent: self,
        association_class: association_class,
        parent_uri_template: :search_results_iri,
        parent_uri_template_canonical: :search_results_iri
      )
    )
  end

  private

  def canonical_iri_opts
    opts = iri_opts
    opts[:parent_iri] = split_iri_segments(parent.try(:canonical_iri_path) || parent&.iri_path)
    opts
  end

  def canonical_iri_template_name
    return @canonical_iri_template_name if @canonical_iri_template_name

    canonical_name ||= @parent_uri_template_canonical || "#{association_class.to_s.tableize}_collection_canonical"
    @canonical_iri_template_name = uri_template(canonical_name) ? canonical_name : iri_template_name
  end

  def iri_template_name
    @parent_uri_template || "#{association_class.to_s.tableize}_collection_iri"
  end

  def new_child_values
    super.merge(
      parent_uri_template_canonical: parent_uri_template_canonical,
      parent_uri_template_opts: parent_uri_template_opts,
      parent_uri_template: parent_uri_template
    )
  end

  def parent_uri_template_opts
    @parent_uri_template_opts.respond_to?(:call) ? @parent_uri_template_opts.call(parent) : @parent_uri_template_opts
  end

  def sanitized_action_url(klass)
    uri = RDF::URI(parent.send("#{klass.to_s.underscore}_collection").iri_template.expand(iri_opts))
    uri.path += '/new'
    uri.query = Rack::Utils.parse_nested_query(uri.query).except('display', 'sort').to_param.presence
    uri
  end

  class << self
    def iri_template_keys
      @iri_template_keys ||= super + %i[iri]
    end
  end
end
