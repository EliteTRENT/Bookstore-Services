class Api::V1::UsersController < ApplicationController
  skip_before_action :authenticate_request

  def create
    # Extract and log the token
    token = request.headers["Authorization"]&.split(" ")&.last
    Rails.logger.info "Received token: #{token}"

    # Attempt to decode token and set current user
    if token
      begin
        decoded = JsonWebToken.decode(token)
        Rails.logger.info "Decoded token: #{decoded.inspect}"
        # Use "user_id" to match the payload from login
        @current_user = User.find_by(id: decoded["user_id"])
        Rails.logger.info "Current user: #{@current_user&.inspect}"
      rescue JWT::DecodeError => e
        Rails.logger.error "Token decode error: #{e.message}"
        @current_user = nil
      rescue ActiveRecord::RecordNotFound
        Rails.logger.error "User not found for decoded token"
        @current_user = nil
      end
    else
      Rails.logger.info "No token provided"
    end

    # Handle user creation based on authentication and role
    if @current_user && @current_user.role == "admin"
      Rails.logger.info "Admin detected, creating user with params: #{user_params.inspect}"
      result = UserService.create(user_params) # Admin can set any role
    else
      Rails.logger.info "Non-admin or unauthenticated, forcing role to customer"
      user_params_with_role = user_params.except(:role).merge(role: "customer")
      result = UserService.create(user_params_with_role)
    end

    if result[:success]
      render json: {
        message: result[:message],
        user: result[:user].slice(:id, :name, :email, :mobile_number, :role)
      }, status: :created
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def login
    begin
      result = UserService.login(login_params)
      if result[:success]
        access_payload = { user_id: result[:user_id], email: result[:email] }
        refresh_payload = { user_id: result[:user_id], email: result[:email] }
        access_token = JsonWebToken.encode(access_payload)
        refresh_token = JsonWebToken.encode_refresh(refresh_payload)

        render json: {
          message: result[:message],
          token: access_token,
          refresh_token: refresh_token,
          user_id: result[:user_id],
          user_name: result[:user_name],
          email: result[:email],
          mobile_number: result[:mobile_number],
          role: result[:role]
        }, status: :ok
      else
        render json: { errors: result[:error] }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { errors: e.message }, status: :unprocessable_entity
    rescue StandardError => e
      Rails.logger.error "Login error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: "Internal server error", details: e.message }, status: :internal_server_error
    end
  end

  def refresh
    refresh_token = params[:refresh_token]
    unless refresh_token
      render json: { errors: "Refresh token required" }, status: :bad_request
      return
    end

    new_token = JsonWebToken.refresh(refresh_token)
    if new_token
      render json: {
        message: "Token refreshed successfully",
        token: new_token[:access_token]
      }, status: :ok
    else
      render json: { errors: "Invalid or expired refresh token" }, status: :unauthorized
    end
  end

  def forgot_password
    result = UserService.forgot_password(forget_params)
    if result[:success]
      render json: { success: true, message: result[:message], otp: result[:otp], user_id: result[:user_id] }, status: :ok
    else
      render json: { success: false, errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def reset_password
    result = UserService.reset_password(params[:id], reset_params)
    if result[:success]
      render json: { success: true, message: result[:message] }, status: :ok
    else
      render json: { success: false, errors: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :mobile_number, :role)
  end

  def login_params
    params.require(:user).permit(:email, :password)
  end

  def forget_params
    params.require(:user).permit(:email)
  end

  def reset_params
    params.require(:user).permit(:new_password, :otp)
  end
end
