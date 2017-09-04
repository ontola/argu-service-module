# frozen_string_literal: true

class Collection
  include Pundit
  include Ldable
  include PragmaticContext::Contextualizable
  include ActiveModel::Serialization
  include ActiveModel::Model
  include ActionDispatch::Routing
  include Rails.application.routes.url_helpers

  attr_accessor :association, :association_class, :association_scope, :filter,
                :name, :page, :pagination, :parent, :parent_view_iri, :title,
                :url_constructor, :user_context

  alias pundit_user user_context

  contextualize_as_type 'argu:Collection'
  contextualize_with_id(&:id)
  contextualize :title, as: 'schema:name'
  contextualize :total_count, as: 'argu:totalCount'

  # prevents a `stack level too deep`
  def as_json(options = {})
    super(options.merge(except: %w[association_class user_context]))
  end

  def create_action
    Action.new(base_iri: uri, filter: query_opts[:filter], type: :create, resource_type: name)
  end

  def id
    uri(query_opts)
  end

  def first
    return unless pagination
    uri(query_opts.merge(page: 1))
  end

  def last
    return unless pagination
    uri(query_opts.merge(page: [total_page_count, 1].max))
  end

  def members
    return if include_pages? || filter?
    @members ||= policy_scope(association_base).includes(included_associations).page(page)
  end

  def next
    return if !pagination || page.nil? || page.to_i >= total_page_count
    uri(query_opts.merge(page: page.to_i + 1))
  end

  def parent_view_iri
    return @parent_view_iri if @parent_view_iri
    uri(query_opts.except(:page)) if page
  end

  def previous
    return if !pagination || page.nil? || page.to_i <= 1
    uri(query_opts.merge(page: page.to_i - 1))
  end

  def views
    if filter?
      association_class.filter_options.map do |key, values|
        values[:values].map { |value| child_with_options(filter: {key => value[0]}) }
      end.flatten
    elsif include_pages?
      [child_with_options(page: 1)]
    end
  end

  def title
    plural = association_class.name.tableize
    I18n.t("#{plural}.collection.#{filter&.values&.join('.').presence || name}",
           default: I18n.t("#{plural}.plural",
                           default: plural.humanize))
  end

  def total_count
    members&.count || association_base.count
  end

  private

  def association_base
    policy_scope(
      (parent&.send(association) || association_class)
        .send(association_scope || :all)
        .joins(joined_associations)
        .where(filter_query)
    )
  end

  def child_with_options(options)
    options = {
      user_context: user_context,
      filter: filter,
      page: page,
      parent_view_iri: id
    }.merge(options)
    parent&.collection_for(name, options) || new_child(options)
  end

  def filter?
    association_class.filter_options.present? && filter.blank? && association_class.filter_options.any? do |_k, v|
      v.present?
    end
  end

  def filter_query
    return if filter.blank?
    queries, values = filter_query_with_values
    [queries.join(' AND '), *values]
  end

  def filter_query_with_values
    queries = []
    values = []
    filter.map do |k, v|
      options = association_class.filter_options.fetch(k)
      value = filter_single_value(options, v)
      values << value unless value.is_a?(String) && value.include?('NULL')
      queries << filter_single_query(options, k, value)
    end
    [queries, values]
  end

  def filter_single_query(options, key, value)
    key = options[:key] || key
    if value.is_a?(String) && value.include?('NULL')
      [key, value].join(' IS ')
    else
      [key, '?'].join(' = ')
    end
  end

  def filter_single_value(options, value)
    options[:values].try(:[], value.try(:to_sym)) || value
  end

  def included_associations
    included_associations = {}
    included_associations[:creator] = :profileable if association_class.reflect_on_association(:creator)
    included_associations[:edge] = :parent if association_class.is_edgeable?
    included_associations
  end

  def joined_associations
    association_class.is_edgeable? ? [:edge] : nil
  end

  def include_pages?
    pagination && page.nil?
  end

  def new_child(options)
    Collection.new(
      options.merge(
        association_class: association_class,
        association_scope: association_scope
      )
    )
  end

  def query_opts
    opts = {}
    opts[:page] = page if page.present?
    opts[:filter] = filter if filter.present?
    opts
  end

  def total_page_count
    (association_base.count / association_class.default_per_page).ceil
  end

  def uri(query_values = '')
    base = if url_constructor.present?
             send(url_constructor, parent.id, protocol: :https)
           else
             url_for([parent, association_class, protocol: :https])
           end
    [base, query_values.to_param].reject(&:empty?).join('?')
  end
end
