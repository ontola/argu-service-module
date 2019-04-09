# frozen_string_literal: true

require_relative 'rails_ld/model'
require_relative 'rails_ld/form_option'
require_relative 'rails_ld/resource'
require_relative 'rails_ld/serializer'
require_relative 'rails_ld/serializers'
require_relative 'rails_ld/shacl'
require_relative 'rails_ld/property_query'
require_relative 'rails_ld/collection'
require_relative 'rails_ld/collection_view'

module RailsLD
  @model_classes = {}

  %i[
    collection
    collection_filter
    collection_sorting
    collection_view
    infinite_collection_view
    paginated_collection_view
  ].each do |klass|
    method = :"#{klass}_class"
    mattr_writer method

    send("#{method}=", "RailsLD::#{klass.to_s.classify}")

    define_singleton_method method do
      @model_classes[method] ||= class_variable_get("@@#{method}").constantize
    end
  end

  mattr_accessor :attribute_label_translation
  mattr_accessor :attribute_description_translation

  self.attribute_label_translation = ->(_class_name, attribute, _locale = I18n.locale) { attribute.to_s.humanize }
  self.attribute_description_translation = ->(_class_name, _attribute, _locale = I18n.locale) { nil }
end
