# frozen_string_literal: true

LinkedRails.app_ns = NS::ARGU

LinkedRails.collection_class = 'Collection'
LinkedRails.collection_filter_class = 'CollectionFilter'
LinkedRails.collection_sorting_class = 'CollectionSorting'
LinkedRails.collection_view_class = 'CollectionView'
LinkedRails.collection_infinite_view_class = 'InfiniteView'
LinkedRails.collection_paginated_view_class = 'PaginatedView'

LinkedRails.actions_item_class = 'Actions::Item'
LinkedRails.menus_item_class = 'Menus::Item'
LinkedRails.entry_point_class = 'EntryPoint'

LinkedRails.controller_parent_class = 'ParentableController'
LinkedRails.policy_parent_class = 'RestrictivePolicy'
LinkedRails.serializer_parent_class = 'BaseSerializer'

LinkedRails.vocabulary_class = 'Ontology'

LinkedRails.iri_mapper_class = 'Argu::IRIMapper'

LinkedRails.whitelisted_spi_ips = ENV['INT_IP_WHITELIST']&.split(',')&.map { |ip| IPAddr.new(ip) } || []

if defined?(LinkedRails::Auth)
  LinkedRails.confirmation_class = 'Users::Confirmation'
  LinkedRails.registration_form_class = 'Users::RegistrationForm'
  LinkedRails.otp_attempt_class = 'OtpAttempt'
  LinkedRails.otp_secret_class = 'OtpSecret'
end

module LinkedRails
  class << self
    def iri(opts = {})
      RDF::DynamicURI(RDF::URI(**{scheme: LinkedRails.scheme, host: LinkedRails.host}.merge(opts)))
    end
  end
end

module LinkedRailsDynamicIRI
  def iri_with_root(_opts = {})
    RDF::DynamicURI(super)
  end

  def iri_path(opts = {})
    root_relative_iri(opts).to_s
  end
end

LinkedRails::Model::Iri.prepend LinkedRailsDynamicIRI

LinkedRails::Translate.translations_for(:property, :description) do |object|
  if object.model_attribute.present?
    model_key = object.model_class.to_s.demodulize.tableize

    I18n.t(
      "#{model_key}.form.#{object.model_attribute}.description",
      default: [
        :"formtastic.placeholders.#{model_key.singularize}.#{object.model_attribute}",
        :"formtastic.placeholders.#{object.model_attribute}",
        :"formtastic.hints.#{model_key.singularize}.#{object.model_attribute}",
        :"formtastic.hints.#{object.model_attribute}",
        ''
      ]
    ).presence
  end
end

LinkedRails::Translate.translations_for(:property, :label) do |object|
  if object.model_attribute.present?
    model_key = object.model_class.to_s.demodulize.tableize

    I18n.t(
      "#{model_key}.form.#{object.model_attribute}.label",
      default: [
        :"formtastic.labels.#{model_key.singularize}.#{object.model_attribute}",
        :"formtastic.labels.#{object.model_attribute}",
        ''
      ]
    ).presence
  end
end
