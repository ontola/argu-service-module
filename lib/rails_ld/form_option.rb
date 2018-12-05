# frozen_string_literal: true

module RailsLD
  class FormOption
    include ActiveModel::Model
    include ActiveModel::Serialization
    include RailsLD::Model

    attr_accessor :attr, :iri, :key, :klass, :type
    attr_writer :label

    def iri_path(_opts = {})
      path = URI(iri)
      path.host = nil
      path.scheme = nil
      path.to_s
    end

    def label
      @label ||
        I18n.t(
          "activerecord.attributes.#{class_name}.#{attr.pluralize}",
          default: [:"#{class_name.tableize}.#{attr}.#{key}", key.to_s.humanize]
        )
    end

    def to_param
      key
    end

    private

    def class_name
      klass.to_s.underscore
    end
  end
end
