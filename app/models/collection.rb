# frozen_string_literal: true

class Collection
  include ActiveModel::Serialization
  include ActiveModel::Model
  include ActionDispatch::Routing
  include Pundit
  include Rails.application.routes.url_helpers

  include Actionable
  include ApplicationModel
  include Ldable
  include Iriable
  include Collection::Filtering
  include Collection::Pagination

  attr_accessor :association, :association_class, :association_scope, :includes, :joins, :name, :order,
                :parent, :type, :url_constructor, :url_constructor_opts,
                :user_context
  attr_writer :parent_view_iri, :title

  EDGE_CLASS = 'Edge'.safe_constantize

  alias pundit_user user_context

  def initialize(attrs = {})
    attrs[:type] = attrs[:type]&.to_sym || :paginated
    attrs[:order] = attrs[:order]&.to_sym || {created_at: :desc}
    super
  end

  # prevents a `stack level too deep`
  def as_json(options = {})
    super(options.merge(except: %w[association_class user_context]))
  end

  def id(path_only = false)
    uri(query_opts, path_only)
  end
  alias iri id

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

  def member_sequence
    @member_sequence ||= RDF::Sequence.new(members)
  end

  def parent_view_iri
    return @parent_view_iri if @parent_view_iri
    return uri(query_opts.except(:page)) if page
    uri(query_opts.except(:before)) if before
  end

  def views
    if filter?
      filter_views
    elsif include_pages?
      [child_with_options(page: 1)]
    elsif include_before?
      [child_with_options(before: Time.current.utc.to_s(:db))]
    end
  end

  def view_sequence
    @view_sequence ||= RDF::Sequence.new(views)
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
    @association_base ||= policy_scope(filtered_association)
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

  def filtered_association
    scope = parent&.send(association) || association_class
    scope = scope.send(association_scope) if association_scope
    scope = scope.joins(joins) if joins
    scope = scope.where(filter_query) if filter_query
    scope
  end

  def new_child(options)
    Collection.new(
      options.merge(
        association_class: association_class,
        association_scope: association_scope
      )
    )
  end

  def path_or_url(path)
    path ? url_constructor.to_s.gsub('_url', '_path') : url_constructor.to_s.gsub('_path', '_url')
  end

  def policy_scope(scope)
    policy_scope = PolicyFinder.new(scope).scope
    policy_scope ? policy_scope.new(pundit_user, scope).resolve : scope
  end

  def query_opts
    opts = {type: type}
    opts[:before] = before if before.present?
    opts[:page] = page if page.present?
    opts[:filter] = filter if filter.present?
    opts
  end

  def uri(query_values = '', path_only = false)
    base =
      if url_constructor.present?
        uri_from_constructor(path_only)
      else
        object = [parent, association_class]
        path_only ? polymorphic_path(object) : polymorphic_url(object, protocol: :https)
      end
    RDF::URI([base, query_values.to_param].reject(&:empty?).join('?'))
  end

  def uri_from_constructor(path_only = false)
    send(
      path_or_url(path_only),
      url_constructor_opts.present? ? nil : parent.id,
      (url_constructor_opts&.call(parent)&.symbolize_keys || {})
        .merge(protocol: :https)
    )
  end
end
