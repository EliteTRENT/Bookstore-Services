# app/controllers/api/v1/google_auth_controller.rb
class Api::V1::GoogleAuthController < ApplicationController
  skip_before_action :authenticate_request, only: :create

  GOOGLE_CLIENT_ID = ENV.fetch("GOOGLE_CLIENT_ID") { raise "GOOGLE_CLIENT_ID must be set" }

  def create
    user = authenticate_with_google(google_params[:token])
    return unless user # Errors are handled in authenticate_with_google

    token = JsonWebToken.encode({ id: user.id, name: user.name, email: user.email })
    refresh_token = JsonWebToken.encode_refresh({ user_id: user.id }, expiration: 30.days.from_now)

    render json: {
      message: "Authentication successful",
      token: token,
      refresh_token: refresh_token,
      user_id: user.id,
      user_name: user.name,
      email: user.email,
      mobile_number: user.mobile_number
    }, status: :ok
  end

  private

  def authenticate_with_google(token)
    validator = GoogleIDToken::Validator.new
    payload = validator.check(token, GOOGLE_CLIENT_ID)
    Rails.logger.info "Google token payload: #{payload.inspect}"
    find_or_create_user(payload)
  rescue GoogleIDToken::ValidationError => e
    Rails.logger.error "Google token validation failed: #{e.message}"
    render_error("Invalid Google token", :unauthorized, details: e.message)
    nil
  end

  def find_or_create_user(payload)
    user = User.find_by(google_id: payload["sub"]) || User.find_by(email: payload["email"])
    if user
      user.update!(google_id: payload["sub"]) unless user.google_id
      Rails.logger.info "Linked Google account to existing user: #{user.id}"
    else
      Rails.logger.info "Attempting to create new user with attributes: #{payload.slice("sub", "email", "name").inspect}"
      user = User.create!(
        google_id: payload["sub"],
        email: payload["email"],
        name: payload["name"]
      )
      Rails.logger.info "New user created: #{user.id}"
    end
    user
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "User validation failed: #{e.message}"
    render_error("Failed to create or update user", :unprocessable_entity, details: e.message)
    nil
  end

  def render_error(message, status, details: nil)
    error_response = { error: message }
    error_response[:details] = details if details
    render json: error_response, status: status
  end

  def google_params
    params.permit(:token)
  end
end