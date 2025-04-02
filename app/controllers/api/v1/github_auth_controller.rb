# app/controllers/api/v1/github_auth_controller.rb
class Api::V1::GithubAuthController < ApplicationController
  skip_before_action :authenticate_request, only: :create

  GITHUB_CLIENT_ID = ENV.fetch("GITHUB_CLIENT_ID") { raise "GITHUB_CLIENT_ID must be set" }
  GITHUB_CLIENT_SECRET = ENV.fetch("GITHUB_CLIENT_SECRET") { raise "GITHUB_CLIENT_SECRET must be set" }

  def create
    user = authenticate_with_github(github_params[:code])
    return unless user 

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

  def authenticate_with_github(code)
    unless code.present?
      render_error("GitHub code is required", :bad_request)
      return nil
    end

    token_response = HTTParty.post(
      "https://github.com/login/oauth/access_token",
      body: {
        client_id: GITHUB_CLIENT_ID,
        client_secret: GITHUB_CLIENT_SECRET,
        code: code
      },
      headers: { "Accept" => "application/json" }
    )

    unless token_response.success? && token_response["access_token"]
      Rails.logger.error "GitHub token exchange failed: #{token_response.inspect}"
      render_error("Invalid GitHub code", :unauthorized, details: token_response["error_description"])
      return nil
    end

    access_token = token_response["access_token"]
    user_response = HTTParty.get(
      "https://api.github.com/user",
      headers: {
        "Authorization" => "Bearer #{access_token}",
        "User-Agent" => "Rails App"
      }
    )

    unless user_response.success?
      Rails.logger.error "GitHub user fetch failed: #{user_response.inspect}"
      render_error("Failed to fetch GitHub user data", :unauthorized)
      return nil
    end

    github_id = user_response["id"].to_s
    email = user_response["email"]
    name = user_response["name"]

    Rails.logger.info "GitHub user payload: #{ { github_id: github_id, email: email, name: name }.inspect }"
    User.from_github(github_id, email, name)
  rescue StandardError => e
    Rails.logger.error "GitHub authentication failed: #{e.message}"
    render_error("GitHub authentication error", :unprocessable_entity, details: e.message)
    nil
  end

  def render_error(message, status, details: nil)
    error_response = { error: message }
    error_response[:details] = details if details
    render json: error_response, status: status
  end

  def github_params
    params.permit(:code)
  end
end
