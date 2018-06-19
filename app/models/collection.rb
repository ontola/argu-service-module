# frozen_string_literal: true

class Collection
  include ActiveModel::Serialization
  include ActiveModel::Model
  include Pundit

  include ApplicationModel
  include Ldable
  include Iriable
  include Collection::Filtering

  attr_accessor :association, :association_class, :association_scope, :joins, :name,
                :parent, :user_context, :parent_uri_template_canonical, :parent_uri_template_opts, :part_of,
                :default_filters, :include_map
  attr_writer :title, :parent_uri_template, :views, :default_type, :unfiltered_collection

  alias pundit_user user_context

  def actions
    return unless user_context.is_a?(UserContext)
    association_class
      .try(:actions_class!)
      &.new(resource: self, user_context: user_context)
      &.actions
  end

  def action(tag)
    actions.find { |a| a.tag == tag }
  end

  # prevents a `stack level too deep`
  def as_json(options = {})
    super(options.merge(except: %w[association_class user_context]))
  end

  def association_base
    @association_base ||= policy_scope(filtered_association)
  end

  def canonical_iri(only_path: false)
    iri(canonical: true, only_path: only_path)
  end

  def default_filtered_collections
    return if filtered? || default_filters.blank?
    @default_filtered_collections ||= default_filters.map { |filter| unfiltered.new_child(filter: filter) }
  end

  def default_view
    @default_view ||= view_with_opts(default_view_opts)
  end

  def inspect
    "#<#{association_class}Collection #{iri} filters=#{filter || []}>"
  end

  def iri(canonical: false, only_path: false)
    RDF::URI(
      expand_uri_template(
        parent_uri_template(canonical),
        iri_opts(canonical).merge(only_path: only_path)
      )
    )
  end
  alias id iri

  def iri_opts(canonical = false)
    opts = {
      parent_iri: canonical ? parent&.canonical_iri(only_path: true) : parent&.iri_path
    }
    opts['filter%5B%5D'] = filter.map { |key, value| "#{key}=#{value}" } if filtered?
    opts.merge(parent_uri_template_opts || {})
  end

  def iri_template
    @iri_template ||= URITemplate.new("#{iri}{?filter%5B%5D,page,page_size,type,before,sort%5B%5D}")
  end

  def new_child(options)
    slice = %w[association association_class association_scope parent_uri_template_canonical
               parent_uri_template_opts user_context parent default_filters]
    attrs =
      options
        .merge(instance_values.slice(*slice))
        .merge(
          parent_uri_template: parent_uri_template,
          unfiltered_collection: filtered? ? @unfiltered_collection : self
        )
    self.class.new(attrs)
  end

  def title
    plural = association_class.name.tableize
    I18n.t("#{plural}.collection.#{filter&.values&.join('.').presence || name}",
           count: ->(_opts) { total_count },
           default: I18n.t("#{plural}.plural",
                           default: plural.humanize))
  end

  def total_count
    @total_count ||= count_from_cache_column || association_base.count
  end

  def unfiltered
    filtered? ? unfiltered_collection : self
  end

  def unfiltered_collection
    @unfiltered_collection ||= new_child(filter: [])
  end

  def views
    @views || [default_view]
  end

  def view_with_opts(opts)
    CollectionView.new(opts.merge(collection: self))
  end

  private

  def count_from_cache_column
    return if filtered?
    parent.children_count(counter_cache_column) if counter_cache_column
  end

  def counter_cache_column
    key = association.to_s.starts_with?('active_') && association.to_s[7..-1]
    opts = association_class.try(:counter_cache_options)
    @counter_cache_column ||= key if key && opts && (opts == true || opts.keys.map(&:to_s).include?(key))
  end

  def default_type
    @default_type || :paginated
  end

  def default_view_opts
    opts = {
      include_map: (include_map || {}).dig(:default_view, :members),
      type: default_type,
      page_size: association_class.default_per_page,
      filter: filter,
      sort: [{predicate: NS::SCHEMA[:dateCreated], direction: :desc}]
    }
    opts[:page] = 1 if default_type == :paginated
    opts[:before] = Time.current.utc.to_s(:db) if default_type == :infinite
    opts
  end

  def filtered_association
    scope = parent&.send(association) || association_class
    scope = scope.send(association_scope) if association_scope
    scope = scope.joins(joins) if joins
    scope = apply_filters(scope) if filtered?
    scope
  end

  def policy_scope(scope)
    policy_scope = PolicyFinder.new(scope).scope
    policy_scope ? policy_scope.new(pundit_user, scope).resolve : scope
  end

  def parent_uri_template(canonical = false)
    if canonical
      @parent_uri_template_canonical || "#{association_class.to_s.tableize}_collection_canonical"
    else
      @parent_uri_template || "#{association_class.to_s.tableize}_collection_iri"
    end
  end
end
