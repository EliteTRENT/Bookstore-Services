class Api::V1::CartsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_user, only: [:get_cart]
  
  def add_book
    result = CartService.add_book(cart_params)
    if result[:success]
      render json: { message: result[:message], cart: result[:cart] }, status: :created
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def get_cart
    result = CartService.get_cart(current_user.id)  # Assuming current_user is set by authentication
    if result[:success]
      render json: { message: result[:message], cart: result[:cart] }, status: :ok
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  # New soft delete action added
  def soft_delete_book
    result = BookSoftDeleteService.new(params[:id]).perform
    
    if result[:success]
      render json: { message: result[:message], book: result[:book] }, status: :ok
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def cart_params
    params.require(:cart).permit(:user_id, :book_id, :quantity)
  end

  def authenticate_user
    token = request.headers['Authorization']&.split(' ')&.last
    Rails.logger.info "Received Token: #{token}"

    if token.nil?
      render json: { error: 'Token is missing' }, status: :unauthorized
      return
    end

    begin
      decoded_token = JWT.decode(token, UserService.get_secret_key, true, algorithm: 'HS256')
      payload = decoded_token.first
      @current_user = User.find_by(email: payload['email'])

      if @current_user.nil?
        render json: { error: 'User not found' }, status: :unauthorized
      end
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT Decode Error: #{e.message}"
      render json: { error: 'Invalid token' }, status: :unauthorized
    end
  end
  
  def current_user
    @current_user
  end
end