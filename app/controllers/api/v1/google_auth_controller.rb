# app/controllers/api/v1/google_auth_controller.rb
class Api::V1::GoogleAuthController < ApplicationController
  skip_before_action :authenticate_request, only: :create

  GOOGLE_CLIENT_ID = ENV.fetch("GOOGLE_CLIENT_ID") { raise "GOOGLE_CLIENT_ID must be set" }
  def create
    user = User.from_google(google_params[:token])
    if user
      token = JsonWebToken.encode({ id: user.id, name: user.name, email: user.email }) # Match normal login
      render json: {
        message: "Authentication successful",
        token: token,
        user_id: user.id,
        user_name: user.name,
        email: user.email,
        mobile_number: user.mobile_number
      }, status: :ok
    else
      render json: { error: "Google authentication failed" }, status: :unprocessable_entity
    end
  end

  private

  def extract_token
    params[:token] || params.dig(:google_auth, :token) || params[:id_token]
  end

  def authenticate_with_google(token)
    validator = GoogleIDToken::Validator.new
    payload = validator.check(token, GOOGLE_CLIENT_ID)
    Rails.logger.info "Google token payload: #{payload.inspect}"

    find_or_create_user(payload)
  rescue GoogleIDToken::ValidationError => e
    Rails.logger.error "Google token validation failed: #{e.message}"
    render_error("Invalid token", :unauthorized, details: e.message)
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
      ) { |u| u.skip_validation = true } # Custom bypass flag or use save!(validate: false) post-initialization
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
