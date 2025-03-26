class Api::V1::WishlistsController < ApplicationController
  before_action :authenticate_request

  def create
    token = request.headers["Authorization"]&.split(" ")&.last
    result = WishlistService.create(token, wishlist_params)
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

  def index
    token = request.headers["Authorization"]&.split(" ")&.last
    result = WishlistService.index(token)
    if result[:success]
      render json: { message: result[:message] }, status: :ok
    elsif result[:error] == "Invalid token"
      render json: { error: result[:error] }, status: :unauthorized
    elsif result[:error] == "User not found"
      render json: { error: result[:error] }, status: :not_found
    else
      # This else block should no longer be reached with the updated service
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def mark_book_as_deleted
    token = request.headers["Authorization"]&.split(" ")&.last
    result = WishlistService.mark_book_as_deleted(token, params[:wishlist_id])
    if result[:success]
      render json: { message: result[:message] }, status: :ok
    elsif result[:error] == "Invalid token"
      render json: { error: result[:error] }, status: :unauthorized
    elsif result[:error] == "User not found"
      render json: { error: result[:error] }, status: :not_found
    else
      render json: { errors: result[:error] }, status: :not_found
    end
  end

  private

  def wishlist_params
    params.require(:wishlist).permit(:book_id)
  end
end
