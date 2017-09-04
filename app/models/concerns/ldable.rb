# frozen_string_literal: true

module Ldable
  extend ActiveSupport::Concern

  included do
    include PragmaticContext::Contextualizable, Ldable::ClassMethods
    contextualize :schema, as: 'http://schema.org/'
    contextualize :hydra, as: 'http://www.w3.org/ns/hydra/core#'
    contextualize :argu, as: 'https://argu.co/ns/core#'

    contextualize :created_at, as: 'http://schema.org/dateCreated'
    contextualize :updated_at, as: 'http://schema.org/dateModified'

    cattr_accessor :filter_options do
      {}
    end
    cattr_accessor :collections do
      []
    end
  end

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
    Collection.new(args)
  end

  def context_id
    self.class.context_id_factory.call(self)
  end

  def context_type
    self.class.context_type_factory&.call(self) || self.class.contextualized_type
  end

  module ClassMethods
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
    # @return [Collection]
    def with_collection(name, options = {})
      options[:association] ||= name.to_sym
      options[:association_class] ||= name.to_s.classify.constantize

      collections << {name: name, options: options}

      define_method "#{name.to_s.singularize}_collection" do |opts = {}|
        collection_for(name, opts)
      end
    end

    def filterable(options = {})
      self.filter_options = HashWithIndifferentAccess.new(options)
    end
  end
end
