# frozen_string_literal: true

class Collection
  include Pundit
  include Ldable
  include ActiveModel::Serialization
  include ActiveModel::Model
  include ActionDispatch::Routing
  include Rails.application.routes.url_helpers
  include Collection::Filtering
  include Collection::Pagination

  attr_accessor :association, :association_class, :association_scope, :includes, :joins, :name, :parent,
                :parent_view_iri, :title, :type, :url_constructor, :url_constructor_opts, :user_context

  EDGEABLE_CLASS = 'Edgeable'.safe_constantize

  alias pundit_user user_context

  def initialize(attrs = {})
    attrs[:type] = attrs[:type]&.to_sym || :paginated
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

  def parent_view_iri
    return @parent_view_iri if @parent_view_iri
    uri(query_opts.except(:page)) if page
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

  def new_child(options)
    Collection.new(
      options.merge(
        association_class: association_class,
        association_scope: association_scope
      )
    )
  end

  def query_opts
    opts = {type: type}
    opts[:before] = before if before.present?
    opts[:page] = page if page.present?
    opts[:filter] = filter if filter.present?
    opts
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
