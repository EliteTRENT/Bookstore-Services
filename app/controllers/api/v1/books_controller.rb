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

  def index
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 10

    result = BookService.get_all_books(page, per_page)
    if result[:success]
      render json: {
        message: result[:message],
        books: result[:books],
        pagination: result[:pagination]
      }, status: :ok
    else
      render json: { errors: result[:error] }, status: :internal_server_error
    end
  end

  def show
    result = BookService.get_book_by_id(params[:id])
    if result[:success]
      render json: { message: result[:message], book: result[:book] }, status: :ok
    else
      render json: { errors: result[:error] }, status: :not_found
    end
  end

  def toggle_delete
    result = BookService.toggle_delete(params[:id])
    if result[:success]
      render json: { message: result[:message], book: result[:book] }, status: :ok
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def destroy
    result = BookService.hard_delete(params[:id])
    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { errors: result[:error] }, status: :not_found
    end
  end

  def search_suggestions
    query = params[:query]
    result = BookService.search_suggestions(query)

    if result[:success]
      render json: {
        message: result[:message],
        suggestions: result[:suggestions]
      }, status: :ok
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def book_params
    params.require(:book).permit(:name, :author, :mrp, :discounted_price, :quantity, :book_details, :genre, :book_image)
  end
end
