class Api::V1::BooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    # Check if a file is uploaded (CSV case) or book params are provided (single book case)
    if params[:books].present?
      result = BookService.create_book(file: params[:books]) # Pass the uploaded file directly
    else
      result = BookService.create_book(book_params) # Use book_params for single book
    end

    if result[:success]
      if result[:books] # CSV case
        render json: { message: result[:message], books: result[:books] }, status: :created
      else # Single book case
        render json: { message: result[:message], book: result[:book] }, status: :created
      end
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
    sort_by = params[:sort_by]

    result = BookService.get_all_books(page, per_page, sort_by)
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
    params.require(:book).permit(
      :name, :author, :mrp, :discounted_price,
      :quantity, :book_details, :genre, :book_image
    )
  end
end