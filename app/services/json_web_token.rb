# app/services/json_web_token.rb (or wherever it’s located)
require "jwt"

class JsonWebToken
  SECRET_KEY = ENV["SECRET_KEY"] || "your-secret-key-here"

  def self.encode(payload, exp = 1.hour.from_now)
    payload[:exp] = exp.to_i
    Rails.logger.info "Encoding JWT with payload: #{payload.inspect}"
    token = JWT.encode(payload, SECRET_KEY, "HS256")
    Rails.logger.info "Generated JWT: #{token}"
    token
  end

  def self.decode(token)
    Rails.logger.info "Decoding JWT: #{token}"
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: "HS256")
    Rails.logger.info "Decoded JWT: #{decoded.inspect}"
    HashWithIndifferentAccess.new(decoded[0])
  rescue JWT::ExpiredSignature
    Rails.logger.warn "JWT expired, needs refresh"
    :expired
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT decode error: #{e.message}"
    nil
  end
end
