# frozen_string_literal: true

class Collection
  include Pundit
  include Ldable
  include ActiveModel::Serialization
  include ActiveModel::Model
  include ActionDispatch::Routing
  include Rails.application.routes.url_helpers

  attr_accessor :association, :association_class, :association_scope, :before, :filter,
                :includes, :joins, :name, :page, :pagination, :parent, :parent_view_iri,
                :title, :type, :url_constructor, :url_constructor_opts, :user_context

  EDGEABLE_CLASS = 'Edgeable'.safe_constantize

  alias pundit_user user_context

  def initialize(attrs = {})
    attrs[:type] = attrs[:type]&.to_sym || :paginated
    unless %i[paginated infinite].include?(attrs[:type])
      raise ActionController::BadRequest.new("'#{attrs[:type]}' is not a valid collection type")
    end
    attrs[:before] = DateTime.parse(attrs[:before]).utc.to_s(:db) if attrs[:before].present?
    super
  end

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
  alias_attribute :iri, :id

  def items_per_page
    association_class.default_per_page
  end

  def first
    case type
    when :paginated
      return unless pagination
      uri(query_opts.merge(page: 1))
    when :infinite
      uri(query_opts.merge(before: DateTime.current.utc.to_s(:db)))
    end
  end

  def last
    return unless paginated? && pagination
    uri(query_opts.merge(page: [total_page_count, 1].max))
  end

  def members
    return if include_before? || include_pages? || filter?
    @members ||=
      case type
      when :paginated
        members_paginated
      when :infinite
        members_infinite
      end
  end

  def next
    case type
    when :paginated
      next_paginated
    when :infinite
      next_infinite
    end
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
      filter_views
    elsif include_pages?
      [child_with_options(page: 1)]
    elsif include_before?
      [child_with_options(before: DateTime.current.utc.to_s(:db))]
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
        .joins(joins)
        .where(filter_query)
    )
  end

  def child_with_options(options)
    options = {
      user_context: user_context,
      filter: filter,
      page: page,
      parent_view_iri: id,
      type: type,
      url_constructor: url_constructor,
      url_constructor_opts: url_constructor_opts
    }.merge(options)
    parent&.collection_for(name, options) || new_child(options.merge(pagination: pagination))
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

  def filter_views
    association_class.filter_options.map do |key, values|
      values[:values].map { |value| child_with_options(filter: {key => value[0]}) }
    end.flatten
  end

  def include_before?
    infinite? && pagination && before.nil?
  end

  def include_pages?
    paginated? && pagination && page.nil?
  end

  def infinite?
    type == :infinite
  end

  def members_infinite
    policy_scope(association_base)
      .includes(includes)
      .where('created_at < ?', before)
      .limit(association_class.default_per_page)
  end

  def members_paginated
    policy_scope(association_base).includes(includes).page(page)
  end

  def new_child(options)
    Collection.new(
      options.merge(
        association_class: association_class,
        association_scope: association_scope
      )
    )
  end

  def next_infinite
    return if !pagination || before.nil?
    uri(query_opts.merge(before: members.last.created_at.utc.to_s(:db)))
  end

  def next_paginated
    return if !pagination || page.nil? || page.to_i >= total_page_count
    uri(query_opts.merge(page: page.to_i + 1))
  end

  def paginated?
    type == :paginated
  end

  def query_opts
    opts = {type: type}
    opts[:before] = before if before.present?
    opts[:page] = page if page.present?
    opts[:filter] = filter if filter.present?
    opts
  end

  def total_page_count
    (association_base.count / items_per_page).ceil
  end

  def uri(query_values = '')
    base = if url_constructor.present?
             send(url_constructor, url_constructor_opts || parent.id, protocol: :https)
           else
             url_for([parent, association_class, protocol: :https])
           end
    RDF::IRI.new [base, query_values.to_param].reject(&:empty?).join('?')
  end
end
