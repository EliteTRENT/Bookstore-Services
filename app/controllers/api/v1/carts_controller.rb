module Api
  module V1
    class CartsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def add_book
        result = CartService.add_book(cart_params)
        if result[:success]
          render json: { message: result[:message], cart: result[:cart] }, status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      def get_cart
        result = CartService.get_cart(params[:user_id])
        render json: result, status: :ok
      end

      def soft_delete_book
        token = request.headers["Authorization"]&.split(" ")&.last
        token_email = JsonWebToken.decode(token)
        user = User.find_by(email: token_email)
        result = CartService.soft_delete_book(params[:id], user.id) # Pass book_id and current_user.id
        if result[:success]
          render json: { message: result[:message], book: result[:book] }, status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      private

      def cart_params
        params.require(:cart).permit(:user_id, :book_id, :quantity)
      end
    end
  end
end
