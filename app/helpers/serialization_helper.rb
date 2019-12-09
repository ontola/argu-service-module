# frozen_string_literal: true

module SerializationHelper
  def serializable_resource(format, resource, scopes, opts = {})
    ActiveModelSerializers::SerializableResource
      .new(resource, {adapter: format, scope: create_user_context(scopes)}.merge(opts))
  end

  def create_user_context(scopes, opts = {})
    UserContext.new({doorkeeper_scopes: scopes}.merge(opts))
  end
end
