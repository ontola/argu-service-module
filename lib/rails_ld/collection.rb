# frozen_string_literal: true

module RailsLD
  class Collection
    include ActiveModel::Serialization
    include ActiveModel::Model
    include RailsLD::Collection::Filtering

    attr_accessor :association, :association_class, :association_scope, :joins, :name,
                  :parent, :part_of, :default_filters, :include_map, :type
    attr_writer :title, :views, :default_type, :unfiltered_collection

    # prevents a `stack level too deep`
    def as_json(options = {})
      super(options.merge(except: %w[association_class user_context]))
    end

    def association_base
      filtered_association
    end

    def default_filtered_collections
      return if filtered? || default_filters.blank?
      @default_filtered_collections ||= default_filters.map { |filter| unfiltered.new_child(filter: filter) }
    end

    def default_view
      @default_view ||= view_with_opts(default_view_opts)
    end

    def new_child(options)
      attrs = options.merge(new_child_values)
      self.class.new(attrs)
    end

    def title
      plural = association_class.name.tableize
      I18n.t("#{plural}.collection.#{filter&.values&.join('.').presence || name}",
             count: ->(_opts) { total_count },
             default: I18n.t("#{plural}.plural",
                             default: plural.humanize))
    end

    def total_count
      @total_count ||= association_base.count
    end

    def unfiltered
      filtered? ? unfiltered_collection : self
    end

    def unfiltered_collection
      @unfiltered_collection ||= new_child(filter: [])
    end

    def views
      @views || [default_view]
    end

    def view_with_opts(opts)
      RailsLD.parent_collection_view.constantize.new(opts.merge(collection: self))
    end

    private

    def default_type
      type&.to_sym || @default_type || :paginated
    end

    def default_view_opts
      opts = {
        include_map: (include_map || {}),
        type: default_type,
        page_size: association_class.default_per_page,
        filter: filter,
        sort: [{predicate: NS::SCHEMA[:dateCreated], direction: :desc}]
      }
      opts[:page] = 1 if default_type == :paginated
      opts[:before] = Time.current.utc.to_s(:db) if default_type == :infinite
      opts
    end

    def filtered_association
      scope = parent&.send(association) || association_class
      scope = scope.send(association_scope) if association_scope
      scope = scope.joins(joins) if joins
      scope = apply_filters(scope) if filtered?
      scope
    end

    def new_child_values
      instance_values
        .slice('association', 'association_class', 'association_scope', 'parent', 'default_filters')
        .merge(
          unfiltered_collection: filtered? ? @unfiltered_collection : self
        )
    end
  end
end
