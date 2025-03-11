class Api::V1::OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    token = request.headers["Authorization"]&.split(" ")&.last
    result = OrderService.create_order(token, order_params)
    if result[:success]
      render json: { message: result[:message], order: result[:order] }, status: :created
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
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def order_params
    params.require(:order).permit(:book_id, :address_id, :quantity)
  end
end
