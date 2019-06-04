# frozen_string_literal: true

LinkedRails.app_ns = NS::ARGU

LinkedRails.collection_class = 'Collection'
LinkedRails.collection_filter_class = 'CollectionFilter'
LinkedRails.collection_sorting_class = 'CollectionSorting'
LinkedRails.collection_view_class = 'CollectionView'
LinkedRails.collection_infinite_view_class = 'InfiniteView'
LinkedRails.collection_paginated_view_class = 'PaginatedView'

LinkedRails.actions_item_class = 'Actions::Item'
LinkedRails.menus_item_class = 'MenuItem'
LinkedRails.rdf_error_class = 'RDFError'
LinkedRails.entry_point_class = 'EntryPoint'

LinkedRails.controller_parent_class = 'ParentableController'
LinkedRails.policy_parent_class = 'RestrictivePolicy'
LinkedRails.serializer_parent_class = 'BaseSerializer'

module LinkedRailsDynamicIRI
  def iri(_opts = {})
    RDF::DynamicURI(super)
  end
end

LinkedRails::Model::Iri.send(:prepend, LinkedRailsDynamicIRI)

LinkedRails::Translate.translations_for(:property, :description) do |object|
  if object.model_attribute.present?
    I18n.t(
      "#{object.model_name.to_s.tableize}.form.#{object.model_attribute}.description",
      default: [
        :"formtastic.placeholders.#{object.model_name.to_s.downcase.singularize}.#{object.model_attribute}",
        :"formtastic.placeholders.#{object.model_attribute}",
        :"formtastic.hints.#{object.model_name.to_s.downcase.singularize}.#{object.model_attribute}",
        :"formtastic.hints.#{object.model_attribute}",
        ''
      ]
    ).presence
  end
end

LinkedRails::Translate.translations_for(:property, :label) do |object|
  if object.model_attribute.present?
    I18n.t(
      "#{object.model_name.to_s.tableize}.form.#{object.model_attribute}.label",
      default: [
        :"formtastic.labels.#{object.model_name.to_s.downcase.singularize}.#{object.model_attribute}",
        :"formtastic.labels.#{object.model_attribute}",
        ''
      ]
    ).presence
  end
end
