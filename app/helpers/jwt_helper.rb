# frozen_string_literal: true
module JWTHelper
  def sign_payload(payload)
    JWT.encode payload, Rails.application.secrets.jwt_encryption_token, 'HS256'
  end

  def decode_token(token, _verify = false)
    JWT.decode(token, Rails.application.secrets.jwt_encryption_token, algorithm: 'HS256')[0]
  end
end
