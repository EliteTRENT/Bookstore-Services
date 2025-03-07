class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  def signup
    result = UserService.signup(user_params)
    if result[:success]
      render json: { message: result[:message], user: result[:user] }, status: :created
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def login
    result = UserService.login(login_params)
    if result[:success]
      render json: { message: result[:message], token: result[:token] }, status: :ok
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def forgetPassword
    result = UserService.forgetPassword(forget_params)
    if result[:success]
      render json: { message: result[:message], otp: result[:otp], user_id: result[:user_id]  }, status: :ok
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def resetPassword
    result = UserService.resetPassword(params[:id], reset_params)
    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
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
