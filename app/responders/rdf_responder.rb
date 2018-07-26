# frozen_string_literal: true

require 'active_response/responders/rdf'

class RDFResponder < ActiveResponse::Responders::RDF
  respond_to(*RDF_CONTENT_TYPES)

  def form(**opts)
    controller.respond_with_resource(resource: opts[:action], include: opts[:include])
  end

  def updated_resource(**opts)
    if opts[:meta].present?
      controller.render(format => [], meta: opts[:meta])
    else
      controller.head :no_content
    end
  end
end
