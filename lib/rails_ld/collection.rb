# frozen_string_literal: true

require_relative 'collection/filtering'
require_relative 'collection/sorting'

module RailsLD
  class Collection
    include ActiveModel::Serialization
    include ActiveModel::Model
    include RailsLD::Collection::Filtering
    include RailsLD::Collection::Sorting

    attr_accessor :association, :association_class, :association_scope, :display, :joins, :name,
                  :parent, :part_of, :include_map, :page_size
    attr_writer :title, :views, :default_type, :type

    # prevents a `stack level too deep`
    def as_json(options = {})
      super(options.merge(except: %w[association_class user_context]))
    end

    def association_base
      filtered_association
    end

    def default_view
      @default_view ||= view_with_opts(default_view_opts)
    end

    def new_child(options)
      attrs = options.merge(new_child_values)
      self.class.new(attrs)
    end

    def title
      return @title.call(parent) if @title.respond_to?(:call)
      @title || title_from_translation
    end

    def title_from_translation
      plural = association_class.name.tableize
      I18n.t("#{plural}.collection.#{filter&.values&.join('.').presence || name}",
             count: ->(_opts) { total_count },
             default: I18n.t("#{plural}.plural",
                             default: plural.humanize))
    end

    def total_count
      @total_count ||= association_base.count
    end

    def type
      @type&.to_sym || default_type
    end

    def views
      @views || [default_view]
    end

    def view_with_opts(opts)
      RailsLD.collection_view_class.new({collection: self, type: type, page_size: page_size}.merge(opts))
    end

    private

    def default_type
      @default_type || :paginated
    end

    def default_view_opts
      opts = {
        include_map: (include_map || {}),
        type: type,
        page_size: page_size || association_class.default_per_page,
        filter: filter
      }
      opts[:page] = 1 if type == :paginated
      opts[:before] = Time.current.utc.to_s(:db) if type == :infinite
      opts
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
