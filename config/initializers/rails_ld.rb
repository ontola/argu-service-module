# frozen_string_literal: true

require_relative '../../lib/rails_ld'

RailsLD.collection_class = 'Collection'
RailsLD.collection_filter_class = 'CollectionFilter'
RailsLD.collection_sorting_class = 'CollectionSorting'
RailsLD.collection_view_class = 'CollectionView'
RailsLD.infinite_collection_view_class = 'InfiniteCollectionView'
RailsLD.paginated_collection_view_class = 'PaginatedCollectionView'

RailsLD.attribute_description_translation = lambda do |class_name, attribute, locale = I18n.locale|
  RailsLD::Translator
    .translation_with_fallbacks(class_name, attribute, locale, 'description', 'placeholders', 'hints')
end

RailsLD.attribute_label_translation = lambda do |class_name, attribute, locale = I18n.locale|
  RailsLD::Translator.translation_with_fallbacks(class_name, attribute, locale, 'label', 'labels')
end

module RailsLD
  module Translator
    class << self
      def translation_with_fallbacks(class_name, attribute, locale, key, *fallbacks)
        return if attribute.blank?
        translation =
          I18n.t(
            "#{class_name.to_s.pluralize}.form.#{attribute}.#{key}",
            default: translation_fallbacks(class_name, attribute, fallbacks),
            locale: locale
          ).presence
        translation unless translation.is_a?(Hash)
      end

      private

      def translation_fallbacks(class_name, attribute, fallbacks)
        fallbacks.map do |fallback|
          [
            :"formtastic.#{fallback}.#{class_name}.#{attribute}",
            :"formtastic.#{fallback}.#{attribute}"
          ]
        end.append('').flatten
      end
    end
  end
end
