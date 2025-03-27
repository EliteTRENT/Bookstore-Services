class Api::V1::WishlistsController < ApplicationController
  def create
    result = WishlistService.create(@current_user, wishlist_params)
    render json: result, status: result[:success] ? :created : :unprocessable_entity
  end

  def index
    result = WishlistService.index(@current_user)
    render json: result, status: :ok
  end

  def mark_book_as_deleted
    result = WishlistService.mark_book_as_deleted(@current_user, params[:wishlist_id])
    render json: result, status: result[:success] ? :ok : :not_found
  end

  private

  def wishlist_params
    params.require(:wishlist).permit(:book_id)
  end
end
