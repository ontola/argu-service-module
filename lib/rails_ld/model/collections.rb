# frozen_string_literal: true

module RailsLD
  module Model
    module Collections
      extend ActiveSupport::Concern

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
          cache_collection(
            name,
            opts.delete(:collection_class) || RailsLD.collection_class,
            opts.merge(**collection_opts)
          )
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
          collection_class = options.delete(:collection_class) || RailsLD.collection_class
          options[:association] ||= name.to_sym
          options[:association_class] ||= name.to_s.classify.constantize

          collections_add(name: name, options: options)

          define_method "#{name.to_s.singularize}_collection" do |opts = {}|
            collection_for(name, opts.merge(collection_class: collection_class))
          end
        end
      end
    end
  end
end
