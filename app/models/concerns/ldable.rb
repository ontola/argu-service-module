# frozen_string_literal: true

module Ldable
  extend ActiveSupport::Concern

  # Initialises a {Collection} for one of the collections defined by {has_collection}
  # @see Ldable#has_collection
  # @param [Hash] name as defined with {has_collection}
  # @param [UserContext] user_context
  # @param [Hash] filter
  # @param [Integer, String] page
  # @param [Hash] opts Additional options to be passed to the collection.
  # @return [Collection]
  def collection_for(name, user_context: nil, filter: {}, page: nil, **opts)
    collection = collections.detect { |c| c[:name] == name }
    args = opts.merge(
      user_context: user_context,
      filter: filter,
      page: page,
      name: name
    ).merge(collection[:options])
    args[:parent] = self
    args[:url_constructor] = args[:url_constructor].call(self) if args[:url_constructor].respond_to?(:call)
    Collection.new(args)
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
    # @option options [Bool] pagination whether to paginate this collection
    # @option options [Sym] url_constructor the method to use to generate the ids
    # @option options [Sym] joins the associations to join
    # @option options [Sym] includes the associations to include
    # @return [Collection]
    def with_collection(name, options = {})
      options[:association] ||= name.to_sym
      options[:association_class] ||= name.to_s.classify.constantize

      collections_add(name: name, options: options)

      define_method "#{name.to_s.singularize}_collection" do |opts = {}|
        collection_for(name, opts)
      end
    end

    def filter_options
      class_variables.include?(:@@filter_options) ? super : {}
    end

    def filterable(options = {})
      cattr_accessor :filter_options do
        HashWithIndifferentAccess.new(options)
      end
    end
  end
end
