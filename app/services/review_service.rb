class ReviewService
  def self.add_review(review_params)
    review = Review.new(review_params)
    if review.save
      { success: true, message: "Review added successfully", review: review }
    else
      { success: false, error: review.errors.full_messages }
    end
  end

  def self.get_reviews(book_id)
    Review.where(book_id: book_id)
  end

  def self.delete_review(review_id)
    review = Review.find_by(id: review_id)
    if review
      review.destroy
      { success: true, message: "Review deleted successfully" }
    else
      { success: false, error: "Review not found" }
    end
  end

end
