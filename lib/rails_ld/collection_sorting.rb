# frozen_string_literal: true

module RailsLD
  class CollectionSorting < RDF::Node
    include ActiveModel::Serialization
    include ActiveModel::Model

    attr_accessor :association_class, :direction, :key

    def sort_value
      return {attribute_name => direction} unless attribute_name.to_s.ends_with?('_count')
      Edge.order_child_count_sql(attribute_name.to_s.gsub('_count', ''), direction: direction)
    end

    private

    def attribute_name
      @attribute_name ||= association_class.predicate_mapping[key].name
    end
  end
end
