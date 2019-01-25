# frozen_string_literal: true

class CurrentUser
  include ActiveModel::Model
  include RailsLD::Model
  extend JWTHelper

  attr_accessor :token, :email, :id, :iri, :scopes, :type, :language
  attr_writer :argu_user

  def guest?
    type == 'guest'
  end

  def respond_to_missing?(method_name, *args)
    argu_user.respond_to?(method_name, *args)
  end

  def to_param
    id
  end

  private

  def argu_user
    @argu_user ||= User.find(id, params: {root_id: ActsAsTenant.current_tenant.uuid})
  end

  def method_missing(method, *args, &block)
    if argu_user.respond_to?(method)
      argu_user.send(method, *args, &block)
    else
      super
    end
  end

  class << self
    def from_response(token, argu_user)
      user = from_token(token)
      user.argu_user = argu_user if user
      user
    end

    def from_token(token)
      return if token.nil?
      new(attributes_from_token(token))
    end

    private

    def attributes_from_token(token) # rubocop:disable Metrics/MethodLength
      token_data = decode_token(token)
      user_data = token_data['user']
      {
        token: token,
        email: user_data['email'],
        id: user_data['id'],
        iri: user_data['@id'] && RDF::DynamicURI(user_data['@id']),
        scopes: token_data['scopes'] || [],
        type: user_data['type'],
        language: user_data['language']
      }
    end
  end
end
