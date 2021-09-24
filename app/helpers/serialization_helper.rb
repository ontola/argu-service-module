# frozen_string_literal: true

module SerializationHelper
  def serializable_resource(resource, scopes, **opts)
    RDF::Serializers.serializer_for(resource)
      .new(resource, {params: {scope: create_user_context(scopes)}}.merge(opts))
  end

  def create_user_context(scopes, **opts)
    UserContext.new(**{doorkeeper_token: Doorkeeper::AccessToken.new(scopes: scopes)}.merge(opts))
  end
end
