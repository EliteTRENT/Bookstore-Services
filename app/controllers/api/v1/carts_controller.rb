class Api::V1::CartsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def add_book
    result = CartService.add_book(cart_params)
    if result[:success]
      render json: { message: result[:message], cart: result[:cart] }, status: :created
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def cart_params
    params.require(:cart).permit(:user_id, :book_id, :quantity)
  end
end
