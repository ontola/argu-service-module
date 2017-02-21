# frozen_string_literal: true
class Collection
  include ActiveModel::Model, ActiveModel::Serialization, PragmaticContext::Contextualizable,
          Ldable, Pundit
  include ActionDispatch::Routing
  include Rails.application.routes.url_helpers

  attr_accessor :association, :association_class, :filter, :name, :page, :pagination,
                :parent, :potential_action, :title, :url_constructor, :user_context

  alias pundit_user user_context

  contextualize_as_type 'argu:Collection'
  contextualize_with_id(&:id)
  contextualize :title, as: 'schema:name'
  contextualize :total_count, as: 'argu:totalCount'

  # prevents a `stack level too deep`
  def as_json(options = {})
    super(options.merge(except: ['association_class']))
  end

  def id
    uri(query_opts)
  end

  def first
    uri(query_opts.merge(page: 1))
  end

  def last
    uri(query_opts.merge(page: [total_page_count, 1].max))
  end

  def members
    return if paginate? || filter?
    @members ||= policy_scope(association_base).includes(included_associations).page(page)
  end

  def next
    return if page.nil? || page.to_i >= total_page_count
    uri(query_opts.merge(page: page.to_i + 1))
  end

  def previous
    return if page.nil? || page.to_i <= 1
    uri(query_opts.merge(page: page.to_i - 1))
  end

  def views
    if filter?
      return association_class.filter_options.map do |key, values|
        values[:values].map { |value| child_with_options(filter: {key => value[0]}) }
      end.flatten
    elsif paginate?
      [child_with_options(page: 1)]
    end
  end

  def title
    I18n.t("#{association_class.name.tableize}.collection.#{filter&.values&.join('.')}",
           default: I18n.t("#{association_class.name.tableize}.plural",
                           default: association_class.name.tableize.humanize))
  end

  def total_count
    members&.count || association_base.count
  end

  private

  def association_base
    policy_scope(
      (parent&.send(association) || association_class)
        .joins(joined_associations)
        .where(filter_query)
    )
  end

  def child_with_options(options)
    options = {
      user_context: user_context,
      filter: filter,
      page: page
    }.merge(options)
    parent&.collection_for(name, options) || Collection.new(options.merge(association_class: association_class))
  end

  def filter?
    association_class.filter_options.present? && filter.empty?
  end

  def filter_query
    return if filter.nil?
    filter_values = []
    [
      filter.map do |k, v|
        key = association_class.filter_options.fetch(k)[:key] || k
        value = association_class.filter_options.fetch(k)[:values].try(:[], v.to_sym) || v
        if value.is_a?(String) && value.include?('NULL')
          [key, value].join(' IS ')
        else
          filter_values <<  value
          [key, '?'].join(' = ')
        end
      end.join(' AND '),
      *filter_values
    ]
  end

  def included_associations
    included_associations = {}
    included_associations[:creator] = :profileable
    included_associations[:edge] = :parent if association_class.is_fertile?
    included_associations
  end

  def joined_associations
    association_class.is_fertile? ? [:edge] : nil
  end

  def paginate?
    pagination && page.nil?
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
