# frozen_string_literal: true

class CurrentUser
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

  def respond_to_missing?(method_name, *args)
    argu_user.respond_to?(method_name, *args)
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
