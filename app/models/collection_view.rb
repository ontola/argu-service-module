# frozen_string_literal: true

class CollectionView
  include ActiveModel::Serialization
  include ActiveModel::Model
  include Pundit

  include ApplicationModel
  include Ldable
  include Iriable
  include Collection::Pagination
  include Collection::Preloading

  attr_accessor :collection, :type, :page, :filter, :sort, :include_map
  attr_writer :members, :page_size
  delegate :association_base, :association_class, :canonical_iri, :parent, :user_context, to: :collection
  delegate :count, to: :raw_members

  alias pundit_user user_context

  def iri(opts = {})
    RDF::URI(collection.unfiltered.iri_template.expand(iri_opts.merge(opts)))
  end
  alias id iri

  def members
    @members ||= preload_included_associations(raw_members.to_a)
  end

  def raw_members
    case type
    when :paginated
      members_paginated
    when :infinite
      members_infinite
    end
  end

  def title
    plural = association_class.name.tableize
    I18n.t("#{plural}.collection.#{filter&.values&.join('.').presence || name}",
           count: total_count,
           default: I18n.t("#{plural}.plural",
                           default: plural.humanize))
  end

  private

  def iri_opts
    {
      before: before,
      page: page,
      pageSize: page_size,
      type: type
    }.merge(collection.iri_opts)
  end
end
