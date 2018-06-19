# frozen_string_literal: true

class Collection
  module Preloading
    private

    def collection_opts_for(key)
      parent.collections.find { |opts| opts[:name].to_s == key[0...-11].pluralize }[:options]
    end

    def preload_association(members, key, reflection)
      return if reflection.nil?
      klass = reflection.klass
      count = reflection.has_one? ? 1 : klass.default_per_page
      preloaded = preload_children(members, klass, count)
      members.each do |member|
        member.send("#{key}=", count == 1 ? preloaded[member.id].first : preloaded[member.id])
      end
    end

    def preload_children(members, klass, count)
      Edge
        .select('*')
        .from(Arel.sql("(#{ranked_children_query(members, klass)}) AS ranked_children"))
        .where('child_rank <= ?', count)
        .includes(klass.includes_for_serializer)
        .each { |child| child.parent = members.find { |member| member.id == child.parent_id } }
        .group_by(&:parent_id)
    end

    def preload_collection(members, key, collection_opts)
      klass = collection_opts[:association_class]
      preloaded = preload_children(members, klass, klass.default_per_page)
      members.each do |member|
        member.send(key, user_context: user_context).default_view.members = preloaded[member.id]
      end
    end

    def preload_included_associations(members)
      include_map&.each do |key, value|
        if key.to_s.ends_with?('_collection')
          preload_collection(members, key, collection_opts_for(key)) if value[:default_view]&.key?(:members)
        else
          preload_association(members, key, reflection_for(key))
        end
      end
      members
    end

    def ranked_children_query(members, klass)
      policy_scope(klass.where(root_id: parent.root_id, parent_id: members.map(&:id))).select(<<-SQL).to_sql
      edges.*,
      dense_rank() OVER (
        PARTITION BY edges.parent_id, edges.owner_type
        ORDER BY edges.created_at DESC
      ) AS child_rank
      SQL
    end

    def reflection_for(key)
      parent.class.reflect_on_association(key)
    end
  end
end
