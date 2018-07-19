# frozen_string_literal: true

class CollectionView
  include ActiveModel::Serialization
  include ActiveModel::Model
  include Pundit

  include ApplicationModel
  include Ldable
  include Iriable
  include Collection::Preloading

  attr_accessor :collection, :filter, :sort, :include_map
  attr_writer :members, :page_size
  delegate :association_base, :association_class, :canonical_iri, :parent, :user_context, to: :collection
  delegate :count, to: :raw_members

  alias pundit_user user_context

  def self.iri
    [super, NS::AS['CollectionPage']]
  end

  def iri(opts = {})
    RDF::URI(collection.unfiltered.iri_template.expand(iri_opts.merge(opts)))
  end
  alias id iri

  def members
    @members ||= preload_included_associations(raw_members.to_a)
  end

  def member_sequence
    @member_sequence ||= RDF::Sequence.new(members)
  end

  def page_size
    @page_size&.to_i || association_class.default_per_page
  end

  def title
    plural = association_class.name.tableize
    I18n.t("#{plural}.collection.#{filter&.values&.join('.').presence || name}",
           count: total_count,
           default: I18n.t("#{plural}.plural",
                           default: plural.humanize))
  end

  private

  def base_count
    @base_count ||= association_base.count
  end

  def parsed_sort_values
    {created_at: :desc}
  end

  def total_page_count
    (base_count / page_size.to_f).ceil if base_count
  end
end
