class Api::V1::OrdersController < ApplicationController
  before_action :authenticate_request

  def update_status
    token = request.headers["Authorization"]&.split(" ")&.last
    result = OrderService.update_order_status(token, params[:id], params[:status])
    if result[:success]
      render json: { message: result[:message], order: result[:order] }, status: :ok
    elsif result[:error] == "Invalid token"
      render json: { error: result[:error] }, status: :unauthorized
    elsif result[:error] == "User not found" || result[:error] == "Order not found"
      render json: { error: result[:error] }, status: :not_found
    else
      render json: { errors: Array(result[:error]) }, status: :unprocessable_entity # Ensure errors is an array
    end
  end

  # Other actions (create, index, show) remain unchanged
  def create
    token = request.headers["Authorization"]&.split(" ")&.last
    result = OrderService.create_order(token, order_params)
    if result[:success]
      render json: { success: true, message: result[:message], order: result[:order] }, status: :created
    elsif result[:error] == "Invalid token"
      render json: { error: result[:error] }, status: :unauthorized
    elsif result[:error] == "User not found" || result[:error] == "Book not found" || result[:error] == "Invalid address"
      render json: { error: result[:error] }, status: :not_found
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def index
    token = request.headers["Authorization"]&.split(" ")&.last
    result = OrderService.get_all_orders(token)
    if result[:success]
      render json: { orders: result[:orders] }, status: :ok
    elsif result[:error] == "Invalid token"
      render json: { error: result[:error] }, status: :unauthorized
    elsif result[:error] == "User not found"
      render json: { error: result[:error] }, status: :not_found
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def show
    token = request.headers["Authorization"]&.split(" ")&.last
    result = OrderService.get_order_by_id(token, params[:id])
    if result[:success]
      render json: { order: result[:order] }, status: :ok
    elsif result[:error] == "Invalid token"
      render json: { error: result[:error] }, status: :unauthorized
    elsif result[:error] == "User not found" || result[:error] == "Order not found"
      render json: { error: result[:error] }, status: :not_found
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def order_params
    params.require(:order).permit(:user_id, :book_id, :address_id, :quantity, :price_at_purchase, :total_price)
  end
end