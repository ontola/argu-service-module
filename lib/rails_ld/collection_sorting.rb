# frozen_string_literal: true

module RailsLD
  class CollectionSorting < RDF::Node
    include ActiveModel::Serialization
    include ActiveModel::Model

    attr_accessor :association_class, :direction, :key

    def sort_value
      {attribute_name => direction}
    end

    private

    def attribute_name
      @attribute_name ||= association_class.predicate_mapping[key].name
    end

    class << self
      def from_array(association_class, array)
        array&.map do |sort|
          new(
            association_class: association_class,
            direction: sort[:direction],
            key: sort[:key]
          )
        end
      end
    end
  end
end
