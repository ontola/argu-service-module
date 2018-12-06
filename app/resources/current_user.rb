# frozen_string_literal: true

class CurrentUser
  include RailsLD::Model
  include JWTHelper

  def initialize(token, attributes: nil)
    @token = token || raise('No user token given')
    @argu_attributes = User.send(:instantiate_record, attributes) if attributes
  end

  %w[email id type language].each do |method|
    define_method method do
      token_attributes['user'][method]
    end
  end

  def guest?
    type == 'guest'
  end

  def iri
    token_attributes['user']['@id'] && RDF::DynamicURI(token_attributes['user']['@id']) || super
  end

  def respond_to_missing?(method_name, *args)
    argu_user.respond_to?(method_name, *args)
  end

  def to_param
    id
  end

  private

  def argu_user
    @argu_attributes ||= User.find(id)
  end

  def method_missing(method, *args, &block)
    if argu_user.respond_to?(method)
      argu_user.send(method, *args, &block)
    else
      super
    end
  end

  def token_attributes
    @token_attributes ||= decode_token(@token)
  end
end
