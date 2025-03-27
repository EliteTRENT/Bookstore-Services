module Api
  module V1
    class CartsController < ApplicationController
      before_action :authenticate_request

      def create
        result = CartService.create(cart_params)
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
        token_full = JsonWebToken.decode(token)
        token_email = token_full["email"]
        user = User.find_by(email: token_email)
        return render json: { error: "User not found" }, status: :unauthorized unless user

        result = CartService.soft_delete_book(params[:book_id], user.id) # Pass book_id and current_user.id
        if result[:success]
          render json: { message: result[:message], book: result[:book] }, status: :ok
        else
          if result[:error] == "Cart item not found"
            render json: { error: result[:error] }, status: :not_found
          else
            render json: { error: result[:error] }, status: :unprocessable_entity
          end
        end
      end

      def update_quantity
        token = request.headers["Authorization"]&.split(" ")&.last
        token_full = JsonWebToken.decode(token)
        token_email = token_full["email"]
        user = User.find_by(email: token_email)
        result = CartService.update_quantity(cart_params, user.id) # Use cart_params
        if result[:success]
          render json: { success: true, message: result[:message], cart: result[:cart] }, status: :ok
        else
          render json: { success: false, error: result[:error] }, status: :unprocessable_entity
        end
      end

      private

      def cart_params
        params.require(:cart).permit(:user_id, :book_id, :quantity)
      end
    end
  end
end
