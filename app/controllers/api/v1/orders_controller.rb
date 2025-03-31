class Api::V1::OrdersController < ApplicationController
  before_action :authenticate_request

  def update_status
    return render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user

    result = OrderService.update_order_status(@current_user.id, params[:id], params[:status])
    handle_response(result)
  end

  def create
    return render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user

    result = OrderService.create_order(@current_user.id, order_params)
    handle_response(result, :created)
  end

  def index
    return render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user

    result = OrderService.index_orders(@current_user.id)
    handle_response(result)
  end

  def show
    return render json: { error: "Unauthorized" }, status: :unauthorized unless @current_user

    result = OrderService.get_order_by_id(@current_user.id, params[:id])
    handle_response(result)
  end

  private

  def order_params
    params.require(:order).permit(:book_id, :address_id, :quantity, :price_at_purchase, :total_price)
  end

  def handle_response(result, success_status = :ok)
    if result[:success]
      render json: result.except(:success), status: success_status
    else
      status = case result[:error]
               when "Invalid token" then :unauthorized
               when "User not found", "Order not found", "Book not found", "Invalid address" then :not_found
               else :unprocessable_entity
               end
      render json: { error: result[:error] }, status: status
    end
  end
end
