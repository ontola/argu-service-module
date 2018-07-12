# frozen_string_literal: true

class InfiniteCollectionView < CollectionView
  attr_accessor :before

  def initialize(attrs = {})
    # rubocop:disable Rails/TimeZone
    attrs[:before] = Time.parse(attrs[:before]).to_s(:db)
    # rubocop:enable Rails/TimeZone
    super
  end

  def first
    iri(iri_opts.merge(before: Time.current.utc.to_s(:db)))
  end

  def last; end

  def next
    return if before.nil? || members.blank?
    iri(iri_opts.merge(before: members.last.created_at.utc.to_s(:db)))
  end

  def previous; end

  def type
    :infinite
  end

  private

  def iri_opts
    {
      before: before,
      pageSize: page_size,
      type: :infinite
    }.merge(collection.iri_opts)
  end

  def raw_members
    association_base
      .includes(association_class.includes_for_serializer)
      .where('created_at < ?', before)
      .order(parsed_sort_values)
      .limit(page_size)
  end
end
