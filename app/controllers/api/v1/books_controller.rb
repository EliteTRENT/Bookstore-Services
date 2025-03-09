class Api::V1::BooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  def create
    result = BookService.create_book(book_params)
    if result[:success]
      render json: { message: result[:message], book: result[:book] }, status: :created
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def update
    result = BookService.update_book(params[:id], book_params)
    if result[:success]
      render json: { message: result[:message], book: result[:book] }, status: :ok
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def book_params
    params.require(:book).permit(:name, :author, :mrp, :discounted_price, :quantity, :book_details, :genre, :book_image)
  end
end
