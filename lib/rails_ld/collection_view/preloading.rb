# frozen_string_literal: true

module RailsLD
  class CollectionView
    module Preloading
      attr_accessor :preloaded
      attr_writer :members

      private

      def collection_opts(key, option)
        parent.collections.find { |opts| opts[:name].to_s == key[0...-11].pluralize }[:options][option]
      end

      def inverse_of_preloaded(child, opts)
        raw_members.find { |member| member.id == child.send(opts[:foreign_key]) }
      end

      def preload_association(key, includes)
        reflection = reflection_for(key)
        return if reflection.nil?
        ActiveRecord::Associations::Preloader
          .new
          .preload(raw_members, key => reflection.klass.reflect_on_all_associations.map(&:name) & includes.keys)
      end

      def preload_collection(key, reflection)
        return if reflection.nil?
        opts = preload_opts(reflection)
        preloaded = preload_collection_members(opts)
        raw_members.each do |member|
          member.send(key, user_context: user_context).default_view.members = preloaded[member.id] || opts[:klass].none
        end
      end

      def preload_collection_members(opts)
        opts[:klass]
          .select('*')
          .from(ranked_query(opts))
          .where('child_rank <= ?', opts[:count])
          .includes(opts[:klass].includes_for_serializer)
          .each { |child| child.send("#{opts[:inverse_of]}=", inverse_of_preloaded(child, opts)) }
          .group_by(&opts[:foreign_key])
      end

      def preload_included_associations
        include_map&.each do |key, value|
          if key.to_s.ends_with?('_collection')
            if value[:default_view]&.key?(:member_sequence)
              preload_collection(key, reflection_for(collection_opts(key, :association)))
            end
          else
            preload_association(key, value)
          end
        end
        self.preloaded = true
      end

      def preload_included_associations?
        !preloaded && association_class < ActiveRecord::Base
      end

      def ranked_query(opts)
        subquery =
          policy_scope(opts[:klass].where(opts[:foreign_key] => raw_members.map(&opts[:primary_key])))
            .select(ranked_query_sql(opts))
            .to_sql
        Arel.sql("(#{subquery}) AS #{opts[:table_name]}")
      end

      def ranked_query_sorting(opts)
        opts[:klass]
          .order(
            RailsLD
              .collection_sorting
              .constantize
              .from_array(opts[:klass], opts[:klass].default_sortings)
              .map(&:sort_value)
          ).order_values
      end

      def ranked_query_sql(opts)
        table_name = opts[:table_name]
        sort = ranked_query_sorting(opts)
        table = Arel::Table.new(table_name)
        partition = Arel::Nodes::Window.new.partition(table[opts[:foreign_key]]).order(sort).to_sql
        "#{table_name}.*, dense_rank() OVER #{partition} AS child_rank"
      end

      def reflection_for(key)
        association_class.reflect_on_association(key)
      end

      def preload_opts(reflection)
        {
          count: reflection.klass.default_per_page,
          foreign_key: reflection.foreign_key.to_sym,
          inverse_of: reflection.inverse_of.name.to_sym,
          klass: reflection.klass,
          table_name: reflection.table_name.to_sym
        }
      end
    end
  end
end
