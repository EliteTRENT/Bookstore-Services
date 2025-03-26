class Api::V1::ReviewsController < ApplicationController
  before_action :authenticate_request, except: [ :show ]

  def create
    result = ReviewService.create(review_params)
    if result[:success]
      render json: { message: result[:message], review: result[:review] }, status: :created
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def show
    result = ReviewService.show(params[:book_id])
    render json: { data: result }, status: :ok
  end

  def destroy
    user_id = params[:user_id] # Expect user_id from the request (e.g., from frontend auth)
    result = ReviewService.destroy(params[:id], user_id)
    if result[:success]
      render json: { message: result[:message] }, status: :ok
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def review_params
    params.require(:review).permit(:user_id, :book_id, :rating, :comment)
  end
end
