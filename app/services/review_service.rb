class ReviewService
  def self.create(review_params)
    review = Review.new(review_params)
    if review.save
      # Clear both individual book cache and all book list caches
      REDIS.del("book:#{review.book_id}")
      REDIS.keys("books:all:*").each { |key| REDIS.del(key) }
      { success: true, message: "Review added successfully", review: review.as_json(include: :user) }
    else
      { success: false, error: review.errors.full_messages }
    end
  end

  def self.show(book_id)
    reviews = Review.where(book_id: book_id).includes(:user).map do |review|
      {
        id: review.id,
        user_id: review.user_id,
        user_name: review.user.name,
        book_id: review.book_id,
        rating: review.rating,
        comment: review.comment,
        created_at: review.created_at,
        updated_at: review.updated_at
      }
    end
    total_reviews = reviews.count
    average_rating = total_reviews > 0 ? (reviews.sum { |r| r[:rating] }.to_f / total_reviews).round(1) : 0
    {
      reviews: reviews,
      total_reviews: total_reviews,
      average_rating: average_rating
    }
  end

  def self.destroy(review_id, user_id)
    review = Review.find_by(id: review_id, user_id: user_id)
    if review
      if review.destroy
        # Clear both individual book cache and all book list caches
        REDIS.del("book:#{review.book_id}")
        REDIS.keys("books:all:*").each { |key| REDIS.del(key) }
        { success: true, message: "Review deleted successfully" }
      else
        { success: false, error: review.errors.full_messages }
      end
    else
      { success: false, error: "Review not found or you don't have permission to delete it" }
    end
  end
end
