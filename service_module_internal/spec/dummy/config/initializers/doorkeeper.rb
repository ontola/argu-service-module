# frozen_string_literal: true

Doorkeeper::JWT.configure do
  encryption_method :hs512
end
