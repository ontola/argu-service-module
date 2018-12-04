# frozen_string_literal: true

module RailsLD
  class Form # rubocop:disable Metrics/ClassLength
    include Iriable
    extend UriTemplateHelper

    class_attribute :_fields, :_property_groups, :_referred_resources
    attr_accessor :user_context, :target

    def initialize(user_context, target)
      @user_context = user_context
      @target = target
    end

    def iri_path(_opts = {})
      iri = URI(target.iri_path)
      iri.fragment = self.class.name
      iri.to_s
    end

    def shape # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      klass =
        if target.is_a?(Class)
          target
        elsif target.new_record?
          target.class
        end
      RailsLD::SHACL::NodeShape.new(
        iri:  iri,
        target_class: klass&.iri,
        target_node: klass ? nil : target.iri,
        property: permitted_properties,
        referred_shapes: _property_groups.values
      )
    end

    private

    def permitted_attributes
      @permitted_attributes ||=
        Pundit
          .policy(user_context, target)
          .permitted_attributes
    end

    def permit_attribute(attr)
      return true if _property_groups[attr[:model_attribute]] || attr[:model_attribute] == :type
      permitted_attributes.find do |p_a|
        if p_a.is_a?(Hash)
          p_a.keys.include?("#{attr[:model_attribute]}_attributes".to_sym)
        else
          p_a == attr[:model_attribute]
        end
      end
    end

    def permitted_properties
      @permitted_properties ||=
        self.class.property_shapes_attrs.select(&method(:permit_attribute)).map(&method(:property_shape))
    end

    def property_shape(attrs)
      RailsLD::SHACL::PropertyShape.new(attrs.merge(form: self))
    end

    def target_class
      target.is_a?(Class) ? target : target.class
    end

    class << self
      def inherited(target)
        target._fields = {}
        target._property_groups = {}
        target._referred_resources = []
      end

      def actor_selector
        {
          custom: true,
          datatype: NS::XSD[:string],
          default_value: ->(resource) { resource.form.user_context.user.iri },
          max_count: 1,
          sh_in: ->(resource) { actors_iri(resource.form.target.root) }
        }
      end

      def model_class
        @model_class ||=
          name.sub(/Form$/, '').safe_constantize ||
          name.deconstantize.classify.sub(/Form$/, '').safe_constantize
      end

      def property_shapes_attrs
        @property_shapes_attrs ||=
          _fields
            .map { |k, attr| property_shape_attrs(k, attr || {}) }
            .compact
      end

      def referred_resources
        property_shapes_attrs
        _referred_resources
      end

      private

      def attr_to_datatype(attr) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
        return nil if method_defined?(attr.name)

        name = attr.name.to_s
        case model_class.attribute_types[name].type
        when :string, :text
          NS::XSD[:string]
        when :integer
          NS::XSD[:integer]
        when :datetime
          NS::XSD[:dateTime]
        when :boolean
          NS::XSD[:boolean]
        when :decimal
          decimal_data_type(name)
        when :file
          NS::LL[:blob]
        else
          NS::XSD[:string] if model_class.defined_enums.key?(name)
        end
      end

      def decimal_data_type(name) # rubocop:disable Metrics/MethodLength
        case model_class.columns_hash[name].precision
        when 64
          NS::XSD[:long]
        when 32
          NS::XSD[:int]
        when 16
          NS::XSD[:short]
        when 8
          NS::XSD[:byte]
        else
          NS::XSD[:decimal]
        end
      end

      def fields(arr, group_iri = nil)
        arr.each do |f|
          key = f.is_a?(Hash) ? f.keys.first : f
          opts = f.is_a?(Hash) ? f.values.first : {}
          field(key, opts.merge(group: group_iri))
        end
      end

      def field(key, opts = {}) # rubocop:disable Metrics/AbcSize
        if key.is_a?(Hash)
          opts.merge!(key.values.first)
          key = key.keys.first
        end
        raise "Resource field '#{key}' defined twice" if _fields[key].present?
        opts[:order] = _fields.keys.length
        _fields[key.try(:to_sym)] = opts
      end

      def form_options(attr, opts)
        opts[:options].map do |key, values|
          RailsLD::FormOption.new({key: key, attr: attr, klass: model_class, type: opts[:type]}.merge(values))
        end
      end

      def literal_or_node_property_attrs(serializer_attr, attrs)
        if serializer_attr.is_a?(ActiveModel::Serializer::Attribute)
          literal_property_attrs(serializer_attr, attrs)
        elsif serializer_attr.is_a?(ActiveModel::Serializer::Reflection)
          node_property_attrs(serializer_attr, attrs)
        end
      end

      def literal_property_attrs(attr, attrs) # rubocop:disable Metrics/AbcSize
        enum = serializer_enum(attr.name.to_sym)
        attrs[:datatype] ||=
          attr.dig(:options, :datatype) ||
          (enum ? NS::XSD[:string] : attr_to_datatype(attr)) ||
          raise("No datatype found for #{attr.name}")
        attrs[:max_count] ||= 1
        attrs[:sh_in] ||= enum && form_options(attr.name.to_s, enum)
        attrs
      end

      def model_attribute(attr)
        (model_class.try(:attribute_alias, attr) || attr).to_sym
      end

      def node_property_attrs(attr, attrs) # rubocop:disable Metrics/AbcSize
        name = attr.dig(:options, :association) || attr.name
        _referred_resources << name
        collection = model_class.try(:collections)&.find { |c| c[:name] == name }
        klass_name = model_class.try(:reflections).try(:[], name.to_s)&.class_name || name.to_s.classify

        attrs[:max_count] ||= collection || attr.is_a?(ActiveModel::Serializer::HasManyReflection) ? nil : 1
        attrs[:sh_class] ||= klass_name.constantize.iri
        attrs[:referred_shapes] ||= ["#{klass_name}Form".safe_constantize]
        attrs
      end

      def predicate_from_serializer(serializer_attr)
        serializer_attr&.dig(:options, :predicate)
      end

      def property_group(name, opts = {}) # rubocop:disable Metrics/AbcSize
        raise "Property group '#{name}' defined twice" if _property_groups[name].present?
        raise "Property group '#{name}' not available in fields" if _fields[name].nil?
        group = RailsLD::SHACL::PropertyGroup.new(
          label: opts[:label],
          iri: opts[:iri]
        )
        _fields[name][:is_group] = true
        _property_groups[name] = group
        fields opts[:properties], group.iri if opts[:properties]
        group
      end

      def property_shape_attrs(attr_key, attrs = {}) # rubocop:disable Metrics/AbcSize
        return if _property_groups.key?(attr_key)
        serializer_attr = serializer_attribute(attr_key)
        attrs[:path] ||= predicate_from_serializer(serializer_attr)
        raise "No predicate found for #{attr_key} in #{name}" if attrs[:path].blank?

        attrs[:model_attribute] ||= model_attribute(attr_key)
        attrs[:validators] ||= validators(attrs[:model_attribute])
        return attrs if attrs.delete(:custom) || serializer_attr.blank?

        literal_or_node_property_attrs(serializer_attr, attrs)
      end

      def serializer_attribute(key)
        return serializer_attributes[key] if serializer_attributes[key]

        k_v = serializer_reflections.find { |_k, v| (v[:options][:association] || v.name) == key }
        k_v[1] if k_v
      end

      def serializer_class
        @serializer_class ||= model_class.try(:serializer_class!)
      end

      def serializer_attributes
        serializer_class&._attributes_data || {}
      end

      def serializer_enum(attr)
        return if serializer_class.blank?
        serializer_class.enum_options(attr)
      end

      def serializer_reflections
        serializer_class&._reflections || {}
      end

      def validators(model_attribute)
        model_class.validators.select { |v| v.attributes.include?(model_attribute) }
      end
    end
  end
end
