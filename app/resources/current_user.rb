# frozen_string_literal: true

class CurrentUser
  include ActiveModel::Model
  include LinkedRails::Model
  extend JWTHelper

  attr_accessor :token, :email, :id, :iri, :scopes, :type, :language
  attr_writer :argu_user

  def doorkeeper_token
    @doorkeeper_token ||= Doorkeeper::AccessToken.new(scopes: scopes)
  end

  def guest?
    type == 'guest'
  end

  def respond_to_missing?(method_name, *args) # rubocop:disable Lint/MissingSuper
    argu_user.respond_to?(method_name, *args)
  end

  def to_param
    id
  end

  private

  def argu_user
    raise('Cannot find user without id') if id.blank?

    @argu_user ||= User.find(id)
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

    def attributes_from_token(token) # rubocop:disable Metrics/AbcSize
      token_data = decode_token(token)
      attrs = {token: token, scopes: token_data['scopes'] || []}
      user_data = token_data['user']
      return attrs if user_data.blank?

      attrs[:email] = user_data['email']
      attrs[:id] = user_data['id']
      attrs[:iri] = LinkedRails.iri(path: user_data['@id'].split(token_data['iss']).last) if user_data['@id']
      attrs[:type] = user_data['type']
      attrs[:language] = user_data['language']
      attrs
    end
  end
end
