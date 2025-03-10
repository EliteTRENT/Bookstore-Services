require 'rails_helper'

RSpec.describe ReviewService, type: :service do
  let!(:user) { User.create!(name: "John Doe", email: "john.doe@gmail.com", password: "Password@123", mobile_number: "9876543210") }
  let!(:user2) { User.create!(name: "Jane Doe", email: "jane.doe@gmail.com", password: "Password@123", mobile_number: "9876543211") }
  let!(:book) { Book.create!(name: "The Great Gatsby", author: "F. Scott Fitzgerald", mrp: 10.99, discounted_price: 9.99, quantity: 10) }

  describe ".add_review" do
    context "with valid attributes" do
      let(:valid_attributes) do
        {
          user_id: user.id,
          book_id: book.id,
          rating: 5,
          comment: "Amazing book!"
        }
      end

      it "creates a review successfully" do
        result = ReviewService.add_review(valid_attributes)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Review added successfully")
        expect(result[:review]).to be_a(Review)
        expect(result[:review].persisted?).to be_truthy
      end
    end

    context "with invalid attributes" do
      it "returns an error when user_id is missing" do
        invalid_attributes = { book_id: book.id, rating: 5, comment: "Great book!" }
        result = ReviewService.add_review(invalid_attributes)
        expect(result[:error]).to include("User must exist")
      end

      it "returns an error when book_id is missing" do
        invalid_attributes = { user_id: user.id, rating: 5, comment: "Great book!" }
        result = ReviewService.add_review(invalid_attributes)
        expect(result[:error]).to include("Book must exist")
      end

      it "returns an error when rating is missing" do
        invalid_attributes = { user_id: user.id, book_id: book.id, comment: "Great book!" }
        result = ReviewService.add_review(invalid_attributes)
        expect(result[:error]).to include("Rating can't be blank")
      end

      it "returns an error when rating is out of range" do
        invalid_attributes = { user_id: user.id, book_id: book.id, rating: 10, comment: "Great book!" }
        result = ReviewService.add_review(invalid_attributes)
        expect(result[:error]).to include("Rating is not included in the list")
      end

      it "returns an error when comment is missing" do
        invalid_attributes = { user_id: user.id, book_id: book.id, rating: 4, comment: "" }
        result = ReviewService.add_review(invalid_attributes)
        expect(result[:error]).to include("Comment can't be blank")
      end
    end

    context "when a user writes multiple reviews for the same book" do
      it "allows multiple reviews from the same user on the same book" do
        first_review = ReviewService.add_review(user_id: user.id, book_id: book.id, rating: 5, comment: "Loved it!")
        second_review = ReviewService.add_review(user_id: user.id, book_id: book.id, rating: 4, comment: "Great read!")

        expect(first_review[:success]).to be_truthy
        expect(second_review[:success]).to be_truthy
        expect(Review.where(user_id: user.id, book_id: book.id).count).to eq(2)
      end
    end
  end

  describe ".get_reviews" do
    context "when reviews exist for the book" do
      before do
        Review.create!(user_id: user.id, book_id: book.id, rating: 5, comment: "Loved it!")
        Review.create!(user_id: user2.id, book_id: book.id, rating: 4, comment: "Great read!")
      end

      it "returns all reviews for the given book" do
        result = ReviewService.get_reviews(book.id)

        expect(result.count).to eq(2)
        expect(result.first).to be_a(Review)
        expect(result.first.book_id).to eq(book.id)
        expect(result.map(&:rating)).to match_array([5, 4])
      end
    end

    context "when no reviews exist for the book" do
      it "returns an empty array" do
        result = ReviewService.get_reviews(book.id)

        expect(result).to be_empty
      end
    end

    context "when an invalid book_id is provided" do
      it "returns an empty array" do
        result = ReviewService.get_reviews(-1) # Invalid book_id
        expect(result).to be_empty
      end
    end
  end

  describe ".delete_review" do
    let!(:review) { Review.create!(user_id: user.id, book_id: book.id, rating: 5, comment: "Loved it!") }

    context "when the review exists" do
      it "deletes the review successfully" do
        result = ReviewService.delete_review(review.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Review deleted successfully")
        expect(Review.find_by(id: review.id)).to be_nil
      end
    end

    context "when the review does not exist" do
      it "returns an error message" do
        result = ReviewService.delete_review(-1) # Invalid review ID

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Review not found")
      end
    end
  end

end
