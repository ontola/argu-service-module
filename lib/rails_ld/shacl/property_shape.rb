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
      attr_writer :description, :min_count

      validations [:min_length, ActiveRecord::Validations::LengthValidator, :minimum],
                  [:max_length, ActiveRecord::Validations::LengthValidator, :maximum],
                  [:pattern, ActiveModel::Validations::FormatValidator, :with],
                  [:sh_in, ActiveModel::Validations::InclusionValidator, :in]

      # The placeholder of the property.
      def description
        description_from_attribute || translation_with_fallbacks('description', 'placeholders', 'hints')
      end

      def min_count
        @min_count || validator_by_class(ActiveRecord::Validations::PresenceValidator).present? ? 1 : nil
      end

      def model_name
        @model_name ||= form.target.model_name.i18n_key
      end

      def name
        translation_with_fallbacks('label', 'labels')
      end

      private

      def description_from_attribute
        return if @description.blank?
        @description.respond_to?(:call) ? @description.call(form.target) : @description
      end

      def translation_fallbacks(fallbacks)
        fallbacks.map do |fallback|
          [
            :"formtastic.#{fallback}.#{model_name}.#{model_attribute}",
            :"formtastic.#{fallback}.#{model_attribute}"
          ]
        end.append('').flatten
      end

      def translation_with_fallbacks(key, *fallbacks)
        return if model_attribute.blank?
        translation =
          I18n.t(
            "#{model_name.to_s.pluralize}.form.#{model_attribute}.#{key}",
            default: translation_fallbacks(fallbacks)
          ).presence
        translation unless translation.is_a?(Hash)
      end

      def validator_by_class(klass)
        validators&.detect { |validator| validator.is_a?(klass) }
      end

      def validator_option(klass, option_key)
        option = validator_by_class(klass)&.options.try(:[], option_key)
        option.respond_to?(:call) ? option.call(form.target) : option
      end
    end
  end
end
