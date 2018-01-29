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
                :parent, :type, :user_context
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

  def canonical_iri(only_path: false)
    uri(query_opts, canonical: true, only_path: only_path)
  end

  def id(only_path = false)
    uri(query_opts, only_path: only_path)
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
      type: type
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

  def uri(query_values, canonical: false, only_path: false)
    RDF::URI(
      expand_uri_template(
        "#{association_class.to_s.tableize}_collection_#{canonical ? 'canonical' : 'iri'}",
        uri_opts(query_values, canonical).merge(only_path: only_path)
      )
    )
  end

  def uri_opts(opts, canonical)
    filters = opts[:filter]&.map { |k, v| [CGI.escape("filter[#{k}]"), v] }
    opts
      .except(:filter)
      .merge(Hash[filters || []])
      .merge(parent_iri: canonical ? parent&.canonical_iri(only_path: true) : parent&.iri(only_path: true))
  end
end
