# frozen_string_literal: true

module RailsLD
  class CollectionView
    include ActiveModel::Serialization
    include ActiveModel::Model
    include Pundit

    include Ldable
    include Iriable
    include RailsLD::CollectionView::Preloading

    attr_accessor :collection, :filter, :sort, :include_map
    attr_writer :page_size
    delegate :association_base, :association_class, :canonical_iri, :parent, :user_context, to: :collection
    delegate :count, to: :members

    alias pundit_user user_context

    def self.iri
      [super, NS::AS['CollectionPage']]
    end

    def iri(opts = {})
      RDF::URI(collection.unfiltered.iri_template.expand(iri_opts.merge(opts)))
    end
    alias id iri

    def member_sequence
      @member_sequence ||= RDF::Sequence.new(members)
    end

    def members
      preload_included_associations if preload_included_associations?
      @members ||= raw_members
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

    def arel_table
      @arel_table ||= Arel::Table.new(association_class.to_s.tableize)
    end

    def base_count
      collection.total_count
    end

    def parsed_sort_values
      {created_at: :desc}
    end

    def total_page_count
      (base_count / page_size.to_f).ceil if base_count
    end

    class << self
      def new(opts = {})
        type = opts.delete(:type)&.to_sym
        return super if type.nil?
        case type
        when :paginated
          paginated_collection_view_class.new(opts)
        when :infinite
          infinite_collection_view_class.new(opts)
        else
          raise ActionController::BadRequest.new("'#{type}' is not a valid collection type")
        end
      end

      def infinite_collection_view_class
        @infinite_collection_view_class ||= RailsLD.infinite_collection_view.constantize
      end

      def paginated_collection_view_class
        @paginated_collection_view_class ||= RailsLD.paginated_collection_view.constantize
      end
    end
  end
end