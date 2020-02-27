# frozen_string_literal: true

module JWTHelper
  def sign_payload(payload)
    JWT.encode payload, Rails.application.secrets.jwt_encryption_token, 'HS256'
  end

  def decode_token(token, secret: Rails.application.secrets.jwt_encryption_token, verify: true)
    JWT.decode(token, secret, verify, algorithms: %w[HS256 HS512])[0]
  end
end
