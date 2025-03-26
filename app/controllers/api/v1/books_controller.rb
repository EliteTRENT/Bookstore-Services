class Api::V1::BooksController < ApplicationController
  # Apply authentication to all actions except 'index' and 'search_suggestions'
  before_action :authenticate_request, except: [ :index, :search_suggestions, :show ]

  def create
    if params[:books].present?
      result = BookService.create_book(file: params[:books])
    else
      result = BookService.create_book(book_params)
    end

    if result[:success]
      if result[:books]
        render json: { message: result[:message], books: result[:books] }, status: :created
      else
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

  def stock
    unless params[:book_ids].present?
      render json: { success: false, error: "book_ids parameter is required" }, status: :bad_request
      return
    end

    book_ids = params[:book_ids].split(",").map(&:to_i)
    result = BookService.fetch_stock(book_ids)

    if result[:success]
      render json: { success: true, stock: result[:stock] }, status: :ok
    else
      render json: { success: false, error: result[:error] }, status: :unprocessable_entity
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
