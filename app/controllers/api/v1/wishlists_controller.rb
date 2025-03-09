class Api::V1::WishlistsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def addBook
    token = request.headers["Authorization"]&.split(" ")&.last
    if token
      token_email = JsonWebToken.decode(token)
      return render json: { error: "Invalid token" }, status: :unauthorized unless token_email
      user = User.find_by(email: token_email)
      return render json: { error: "User not found" }, status: :not_found unless user
      book = Book.find_by(id: wishlist_params[:book_id])
      return render json: { error: "Book not found" }, status: :not_found unless book
      result = WishlistService.addBook(user, book)
      if result[:success]
        render json: { message: result[:message] }, status: :created
      else
        render json: { errors: result[:error] }, status: :unprocessable_entity
      end
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
  private

  def wishlist_params
    params.require(:wishlist).permit(:book_id)
  end
end
