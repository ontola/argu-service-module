# frozen_string_literal: true

require 'active_response/responders/json'

class EmpJsonResponder < ActiveResponse::Responders::JSON
  respond_to :empjson

  def resource(**opts)
    opts[:empjson] = opts.delete(:resource)
    controller.render opts
  end
end

ActionController::Renderers.add :empjson do |resource, options|
  self.content_type = 'application/empathy+json'
  serializer_opts = RDF::Serializers::Renderers.transform_opts(
    options,
    respond_to?(:serializer_params, true) ? serializer_params : {}
  )
  serializer = RDF::Serializers.serializer_for(resource)&.new(resource, serializer_opts)

  serializer&.dump(:empjson, options.merge(resource: resource, symbolize: true))
end
