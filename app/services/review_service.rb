class ReviewService
  def self.add_review(review_params)
    review = Review.new(review_params)
    if review.save
      { success: true, message: "Review added successfully", review: review }
    else
      { success: false, error: review.errors.full_messages }
    end
  end

  
end
