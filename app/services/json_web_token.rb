# app/services/json_web_token.rb
require "jwt"

class JsonWebToken
  SECRET_KEY = ENV["SECRET_KEY"] || "your-secret-key-here"
  REFRESH_SECRET_KEY = ENV["REFRESH_SECRET_KEY"] || "your-refresh-secret-key-here" # Separate key for refresh tokens

  # Encode an access token (short-lived, e.g., 15 minutes)
  def self.encode(payload, expiration: 15.minutes.from_now)
    payload[:exp] = expiration.to_i
    Rails.logger.info "Encoding JWT access token with payload: #{payload.inspect}"
    token = JWT.encode(payload, SECRET_KEY, "HS256")
    Rails.logger.info "Generated JWT access token: #{token}"
    token
  end

  # Encode a refresh token (long-lived, e.g., 30 days)
  def self.encode_refresh(payload, expiration: 30.days.from_now)
    payload[:exp] = expiration.to_i
    Rails.logger.info "Encoding JWT refresh token with payload: #{payload.inspect}"
    token = JWT.encode(payload, REFRESH_SECRET_KEY, "HS256")
    Rails.logger.info "Generated JWT refresh token: #{token}"
    token
  end

  # Decode an access token
  def self.decode(token)
    Rails.logger.info "Decoding JWT access token: #{token}"
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: "HS256")
    Rails.logger.info "Decoded JWT access token: #{decoded.inspect}"
    HashWithIndifferentAccess.new(decoded[0])
  rescue JWT::ExpiredSignature
    Rails.logger.warn "JWT access token expired, needs refresh"
    :expired
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT access token decode error: #{e.message}"
    nil
  end

  # Decode a refresh token
  def self.decode_refresh(token)
    Rails.logger.info "Decoding JWT refresh token: #{token}"
    decoded = JWT.decode(token, REFRESH_SECRET_KEY, true, algorithm: "HS256")
    Rails.logger.info "Decoded JWT refresh token: #{decoded.inspect}"
    HashWithIndifferentAccess.new(decoded[0])
  rescue JWT::ExpiredSignature
    Rails.logger.warn "JWT refresh token expired"
    :expired
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT refresh token decode error: #{e.message}"
    nil
  end

  # Refresh method to generate a new access token using a refresh token
  def self.refresh(refresh_token)
    decoded_refresh = decode_refresh(refresh_token)
    return nil if decoded_refresh.nil? || decoded_refresh == :expired

    # Create a new access token payload based on the refresh token’s data
    payload = { user_id: decoded_refresh[:user_id] } # Adjust fields as needed
    new_access_token = encode(payload)
    Rails.logger.info "Refreshed access token generated: #{new_access_token}"
    { access_token: new_access_token }
  end
end