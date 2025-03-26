class Api::V1::ReviewsController < ApplicationController
  before_action :authenticate_request, except: [ :get_reviews ]

  def add_review
    result = ReviewService.add_review(review_params)
    if result[:success]
      render json: { message: result[:message], review: result[:review] }, status: :created
    else
      render json: { errors: result[:error] }, status: :unprocessable_entity
    end
  end

  def get_reviews
    result = ReviewService.get_reviews(params[:book_id])
    render json: { data: result }, status: :ok
  end

  def delete_review
    user_id = params[:user_id] # Expect user_id from the request (e.g., from frontend auth)
    result = ReviewService.delete_review(params[:id], user_id)
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
