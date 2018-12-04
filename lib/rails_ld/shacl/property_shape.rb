# frozen_string_literal: true

module RailsLD
  module SHACL
    class PropertyShape < Shape
      class << self
        def iri
          NS::SH[:PropertyShape]
        end

        def validations(*validations)
          validations.each do |key, klass, option_key|
            attr_writer key

            define_method key do
              instance_variable_get(:"@#{key}") || validator_option(klass, option_key)
            end
          end
        end
      end

      # Custom attributes
      attr_accessor :model_attribute, :form

      # SHACL attributes
      attr_accessor :sh_class,
                    :datatype,
                    :default_value,
                    :group,
                    :model_class,
                    :node,
                    :node_kind,
                    :node_shape,
                    :max_count,
                    :order,
                    :path,
                    :validators
      attr_writer :description

      validations [:min_count, ActiveRecord::Validations::PresenceValidator, :min_count],
                  [:min_length, ActiveRecord::Validations::LengthValidator, :minimum],
                  [:max_length, ActiveRecord::Validations::LengthValidator, :maximum],
                  [:pattern, ActiveModel::Validations::FormatValidator, :with],
                  [:sh_in, ActiveModel::Validations::InclusionValidator, :in]

      # The placeholder of the property.
      def description
        description_from_attribute || description_from_translation
      end

      def model_name
        @model_name ||= form.target.model_name.i18n_key
      end

      def name
        return if model_attribute.blank?
        name =
          I18n.t("#{model_name}.form.#{model_attribute}_heading",
                 default: [
                   :"formtastic.labels.#{model_name}.#{model_attribute}",
                   :"formtastic.labels.#{model_attribute}",
                   ''
                 ])
        name unless name.is_a?(Hash)
      end

      private

      def description_from_attribute
        return if @description.blank?
        @description.respond_to?(:call) ? @description.call(form.target) : @description
      end

      # Translations are currently all-over-the-place, so we need some nesting, though
      # doesn't include a generic fallback mechanism yet.
      def description_from_translation
        return if model_attribute.blank?
        description =
          I18n.t("formtastic.placeholders.#{model_name}.#{model_attribute}",
                 default: [
                   :"formtastic.placeholders.#{model_attribute}",
                   :"formtastic.hints.#{model_name}.#{model_attribute}",
                   :"formtastic.hints.#{model_attribute}",
                   ''
                 ]).presence
        description unless description.is_a?(Hash)
      end

      def validator_option(klass, option_key)
        option = validators&.detect { |validator| validator.is_a?(klass) }&.options.try(:[], option_key)
        option.respond_to?(:call) ? option.call(form.target) : option
      end
    end
  end
end
