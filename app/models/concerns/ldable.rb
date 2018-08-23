# frozen_string_literal: true

module Ldable
  extend ActiveSupport::Concern

  included do
    class_attribute :default_sortings
    self.default_sortings = [{key: NS::SCHEMA[:dateCreated], direction: :desc}]
  end

  def applicable_filters
    Hash[self.class.filter_options.keys.map { |k| [k, send(k)] }]
  end

  # Initialises a {Collection} for one of the collections defined by {has_collection}
  # @see Ldable#has_collection
  # @param [Hash] name as defined with {has_collection}
  # @param [UserContext] user_context
  # @param [Hash] filter
  # @param [Integer, String] page
  # @param [ApplicationRecord] part_of
  # @param [Hash] opts Additional options to be passed to the collection.
  # @return [Collection]
  def collection_for(name, opts = {})
    collection_opts = collections.detect { |c| c[:name] == name }.try(:[], :options)
    return if collection_opts.blank?
    cached_collection(name, opts[:filter]) ||
      cache_collection(name, (opts.delete(:collection_class) || Collection), opts.merge(**collection_opts))
  end

  private

  def cache_collection(name, collection_class, opts)
    opts[:name] = name
    opts[:parent] = self
    opts[:filter] ||= {}
    opts[:part_of] = opts.key?(:part_of) ? send(opts[:part_of]) : self
    collection = collection_class.new(opts)
    @collection_instances[name] = collection if opts[:filter].blank?
    collection
  end

  def cached_collection(name, filter)
    @collection_instances ||= {}
    @collection_instances[name] if filter.blank?
  end

  module ClassMethods
    def collections
      class_variables.include?(:@@collections) ? super : []
    end

    def collections_add(opts)
      unless class_variables.include?(:@@collections)
        cattr_accessor :collections do
          []
        end
      end
      collections.delete_if { |c| c[:name] == opts[:name] }
      collections.append(opts)
    end

    attr_accessor :context_type_factory

    def contextualize_with_type(&block)
      raise 'contextualize_with_type must be called with a block' unless block_given?
      self.context_type_factory = block
    end

    # Defines a collection to be used in {collection_for}
    # @see Ldable#collection_for
    # @note Adds a instance_method <name>_collection
    # @param [Hash] name as to be used in {collection_for}
    # @param [Hash] options
    # @option options [Sym] association the name of the association
    # @option options [Class] association_class the class of the association
    # @option options [Sym] joins the associations to join
    # @return [Collection]
    def with_collection(name, options = {})
      collection_class = options.delete(:collection_class) || Collection
      options[:association] ||= name.to_sym
      options[:association_class] ||= name.to_s.classify.constantize

      collections_add(name: name, options: options)

      define_method "#{name.to_s.singularize}_collection" do |opts = {}|
        collection_for(name, opts.merge(collection_class: collection_class))
      end
    end

    def filter_options
      class_variables.include?(:@@filter_options) ? super : {}
    end

    def filterable(options = {})
      cattr_accessor :filter_options do
        HashWithIndifferentAccess.new(options)
      end

      options.map { |k, filter| define_filter_method(k, filter) }
    end

    def includes_for_serializer
      {}
    end

    def predicate_mapping
      @predicate_mapping ||= Hash[attribute_mapping + reflection_mapping]
    end

    private

    def attribute_mapping
      ActiveModel::Serializer.serializer_for(self)
        ._attributes_data
        .values
        .select { |value| value.options[:predicate].present? }
        .map { |value| [value.options[:predicate], value] }
    end

    def define_filter_method(k, filter)
      return if method_defined?(k) || filter[:attr].blank?

      enum_map = defined_enums[filter[:attr].to_s]

      if enum_map
        define_enum_filter_method(k, filter, enum_map)
      else
        define_plain_filter_method(k, filter)
      end
    end

    def define_enum_filter_method(k, filter, enum_map)
      define_method k do
        filter[:values].key(enum_map[send(filter[:attr])])
      end

      define_method "#{k}=" do |value|
        send("#{filter[:attr]}=", enum_map.key(filter[:values][value&.to_sym]))
      end
    end

    def define_plain_filter_method(k, filter)
      define_method k do
        filter.values[send(filter[:attr])]
      end

      define_method "#{k}=" do |value|
        send("#{filter[:attr]}=", filter[:values].key(value))
      end
    end

    def reflection_mapping
      ActiveModel::Serializer.serializer_for(self)
        ._reflections
        .values
        .select { |value| value.options[:predicate].present? }
        .map { |value| [value.options[:predicate], value] }
    end
  end

  module Serializer
    extend ActiveSupport::Concern

    included do
      def self.with_collection(name, opts = {})
        collection_name = "#{name.to_s.singularize}_collection"

        has_one collection_name, opts.merge(association: name)

        define_method collection_name do
          object.send(collection_name, user_context: scope)
        end
      end
    end
  end
end
