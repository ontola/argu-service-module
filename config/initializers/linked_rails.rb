# frozen_string_literal: true

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

LinkedRails.ontology_class = 'Ontology'
LinkedRails.ontology_class_class = 'Ontology::Class'

LinkedRails.iri_mapper_class = 'Argu::IRIMapper'

LinkedRails.whitelisted_spi_ips = ENV['INT_IP_WHITELIST']&.split(',')&.map { |ip| IPAddr.new(ip) } || []

LinkedRails::Renderers.register!

if defined?(LinkedRails::Auth)
  LinkedRails.confirmation_class = 'Users::Confirmation'
  LinkedRails.password_class = 'Users::Password'
  LinkedRails.access_token_form_class = 'Users::AccessTokenForm'
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
end

LinkedRails::Model::Iri.prepend LinkedRailsDynamicIRI
