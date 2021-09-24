# frozen_string_literal: true

class Collection < LinkedRails::Collection
  include Collection::CounterCache
  include IRITemplateHelper

  def search_result_collection(params = {})
    return unless association_class.enhanced_with?(Searchable)

    SearchResult.root_collection_class.collection_or_view(
      SearchResult.root_collection_opts.merge(
        association_class: association_class,
        parent: self
      ),
      params
    )
  end

  attr_accessor :parent_uri_template
  attr_writer :parent_uri_template_opts

  delegate :searchable_aggregations, to: :association_class

  def action_triples
    return super unless association_class.to_s == 'Discussion'

    triples = super
    Discussion.descendants.each do |klass|
      next unless parent.respond_to?("#{klass.to_s.underscore}_collection")

      triples << RDF::Statement.new(iri, NS.ontola[:createAction], iri_with_root(sanitized_action_url(klass)))
    end
    triples
  end

  def clear_total_count
    parent&.reload
    @total_count = nil
  end

  def iri(**opts)
    return super if ActsAsTenant.current_tenant.present? || parent.blank?
    return @iri if @iri && opts.blank?

    iri = ActsAsTenant.with_tenant(parent.root) { super }
    @iri = iri if opts.blank?
    iri
  end

  def iri_opts
    opts = super
    iri_opts_add(opts, :parent_iri, split_iri_segments(parent&.root_relative_iri))
    iri_opts_add(opts, :iri, parent&.iri_opts.try(:[], :iri))
    opts.merge(parent_uri_template_opts || {})
  end

  # def search_result(**opts)
  #   SearchResult.new(
  #     opts.merge(
  #       parent: self,
  #       association_class: association_class,
  #       parent_uri_template: :search_results_iri,
  #       parent_uri_template_canonical: :search_results_iri
  #     )
  #   )
  # end

  private

  def iri_template_name
    @parent_uri_template || "#{association_class.to_s.tableize}_collection_iri"
  end

  def new_child_values
    super.merge(
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
