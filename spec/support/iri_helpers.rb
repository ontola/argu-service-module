# frozen_string_literal: true

module IriHelpers
  include URITemplateHelper

  def resource_iri(resource, iri_prefix: "#{ENV['HOSTNAME']}/argu")
    resource.instance_variable_set(:@iri, nil) if resource.instance_variable_get(:@iri)
    ActsAsTenant.with_tenant(Page.new(iri_prefix: iri_prefix, display_name: 'Page name')) do
      if resource.respond_to?(:iri)
        resource.iri
      elsif resource.is_a?(RDF::URI)
        resource
      else
        RDF::DynamicURI(resource)
      end
    end
  end
end
