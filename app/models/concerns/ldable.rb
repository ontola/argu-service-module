# frozen_string_literal: true
module Ldable
  extend ActiveSupport::Concern

  included do
    include PragmaticContext::Contextualizable
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
    def self.has_collection(name, options = {})
      options[:association] ||= name.to_sym
      options[:association_class] ||= name.to_s.classify.constantize

      collections << {name: name, options: options}

      define_method "#{name.to_s.singularize}_collection" do |opts = {}|
        collection_for(name, opts)
      end
    end

    # Initialises a {Collection} for one of the collections defined by {has_collection}
    # @see Ldable#has_collection
    # @param [Hash] name as defined with {has_collection}
    # @param [UserContext] user_context
    # @param [Hash] filter
    # @param [Integer, String] page
    # @return [Collection]
    def collection_for(name, user_context: nil, filter: {}, page: nil)
      collection = collections.detect { |c| c[:name] == name }
      opts = {
        user_context: user_context, filter: filter, page: page, name: name
      }.merge(collection[:options])
      opts[:parent] = self
      Collection.new(opts)
    end

    def context_id
      self.class.context_id_factory.call(self)
    end

    def self.filterable(options = {})
      self.filter_options = HashWithIndifferentAccess.new(options)
    end
  end
end
