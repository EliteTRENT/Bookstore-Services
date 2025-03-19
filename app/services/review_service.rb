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
    reviews = Review.where(book_id: book_id)
    total_reviews = reviews.count
    average_rating = total_reviews > 0 ? (reviews.sum(:rating).to_f / total_reviews).round(1) : 0

    {
      reviews: reviews,
      total_reviews: total_reviews,
      average_rating: average_rating
    }
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
