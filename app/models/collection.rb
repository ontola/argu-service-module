# frozen_string_literal: true

class Collection < LinkedRails::Collection
  include Collection::CounterCache
  include IRITemplateHelper

  def action_dialog
    association_class.try(:action_dialog, self)
  end

  def action_precedence
    association_class.try(:action_precedence)
  end

  def search_result_collection(params = {})
    return unless association_class.enhanced_with?(Searchable)

    SearchResult.default_collection_option(:collection_class).collection_or_view(
      SearchResult.default_collection_options.merge(
        association_class: association_class,
        parent: self
      ),
      params
    )
  end

  delegate :searchable_aggregations, to: :association_class

  private

  def iri_template_parent_iri
    return super unless Rails.application.config.try(:iri_suffix)

    LinkedRails.iri(path: LinkedRails.iri_mapper.send(:sanitized_path, URI(super))).to_s.chomp('/')
  end
end
