class Api::V1::UsersController < ApplicationController
  skip_before_action :authenticate_request, only: [ :signup, :login, :forgetPassword, :resetPassword]
  def signup
    result = UserService.signup(user_params)
    if result[:success]
      render json: { message: result[:message], user: result[:user] }, status: :created
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def login
    begin
      result = UserService.login(login_params)
      if result[:success]
        render json: {
          message: result[:message],
          token: result[:token],
          user_id: result[:user_id],
          user_name: result[:user_name],
          email: result[:email],
          mobile_number: result[:mobile_number]
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

  def forgetPassword
    result = UserService.forgetPassword(forget_params)
    if result[:success]
      render json: { success: true, message: result[:message], otp: result[:otp], user_id: result[:user_id]  }, status: :ok
    else
      render json: { success: false, errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def resetPassword
    result = UserService.resetPassword(params[:id], reset_params)
    if result[:success]
      render json: { success: true, message: result[:message] }, status: :ok
    else
      render json: { success: false, errors: result[:error] }, status: :unprocessable_entity
    end
  end

  private
  def user_params
    params.require(:user).permit(:name, :email, :password, :mobile_number)
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
