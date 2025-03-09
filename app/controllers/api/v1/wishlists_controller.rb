class Api::V1::WishlistsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def addBook
    token = request.headers["Authorization"]&.split(" ")&.last
    result = WishlistService.addBook(token, wishlist_params)
    if result[:success]
      render json: { message: result[:message] }, status: :created
    elsif result[:error] == "Invalid token"
      render json: { error: result[:error] }, status: :unauthorized
    elsif result[:error] == "User not found" || result[:error] == "Book not found"
      render json: { error: result[:error] }, status: :not_found
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def getAll
    token = request.headers["Authorization"]&.split(" ")&.last
    result = WishlistService.getAll(token)
    if result[:success]
      render json: { message: result[:wishlists] }, status: :ok
    elsif result[:error] == "Invalid token"
      render json: { error: result[:error] }, status: :unauthorized
    elsif result[:error] == "User not found"
      render json: { error: result[:error] }, status: :not_found
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def wishlist_params
    params.require(:wishlist).permit(:book_id)
  end
end
