require 'rails_helper'

RSpec.describe ReviewService, type: :service do
  let!(:user) { User.create!(name: "John Doe", email: "john.doe@gmail.com", password: "Password@123", mobile_number: "9876543210") }
  let!(:user2) { User.create!(name: "Jane Doe", email: "jane.doe@gmail.com", password: "Password@123", mobile_number: "9876543211") }
  let!(:book) { Book.create!(name: "The Great Gatsby", author: "F. Scott Fitzgerald", mrp: 10.99, discounted_price: 9.99, quantity: 10) }

  # Stub Redis interactions before all tests to avoid connection errors
  before do
    allow(REDIS).to receive(:del) # Stub REDIS.del to do nothing
    allow(REDIS).to receive(:keys).and_return([]) # Stub REDIS.keys to return an empty array
  end

  describe ".create" do
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
        result = ReviewService.create(valid_attributes)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Review added successfully")

        # Validate the returned review as a hash
        expect(result[:review]).to be_a(Hash)
        expect(result[:review]["user_id"]).to eq(user.id)
        expect(result[:review]["book_id"]).to eq(book.id)
        expect(result[:review]["rating"]).to eq(5)
        expect(result[:review]["comment"]).to eq("Amazing book!")
      end
    end

    context "with invalid attributes" do
      it "returns an error when user_id is missing" do
        invalid_attributes = { book_id: book.id, rating: 5, comment: "Great book!" }
        result = ReviewService.create(invalid_attributes)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("User must exist")
      end

      it "returns an error when book_id is missing" do
        invalid_attributes = { user_id: user.id, rating: 5, comment: "Great book!" }
        result = ReviewService.create(invalid_attributes)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Book must exist")
      end

      it "returns an error when rating is missing" do
        invalid_attributes = { user_id: user.id, book_id: book.id, comment: "Great book!" }
        result = ReviewService.create(invalid_attributes)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Rating can't be blank")
      end

      it "returns an error when rating is out of range" do
        invalid_attributes = { user_id: user.id, book_id: book.id, rating: 10, comment: "Great book!" }
        result = ReviewService.create(invalid_attributes)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Rating is not included in the list")
      end

      it "returns an error when comment is missing" do
        invalid_attributes = { user_id: user.id, book_id: book.id, rating: 4, comment: "" }
        result = ReviewService.create(invalid_attributes)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Comment can't be blank")
      end
    end

    context "when a user writes multiple reviews for the same book" do
      it "allows multiple reviews from the same user on the same book" do
        first_review = ReviewService.create(user_id: user.id, book_id: book.id, rating: 5, comment: "Loved it!")
        second_review = ReviewService.create(user_id: user.id, book_id: book.id, rating: 4, comment: "Great read!")

        expect(first_review[:success]).to be_truthy
        expect(second_review[:success]).to be_truthy

        # Ensure multiple reviews by the same user are saved
        expect(Review.where(user_id: user.id, book_id: book.id).count).to eq(2)
      end
    end
  end

  describe ".show" do
    context "when reviews exist for the book" do
      before do
        ReviewService.create(user_id: user.id, book_id: book.id, rating: 5, comment: "Loved it!")
        ReviewService.create(user_id: user2.id, book_id: book.id, rating: 4, comment: "Great read!")
      end

      it "returns all reviews for the given book" do
        result = ReviewService.show(book.id)

        expect(result).to include(:reviews, :average_rating, :total_reviews)

        # Validate the total number of reviews
        expect(result[:total_reviews]).to eq(2)

        # Validate the reviews content
        expect(result[:reviews]).to be_an(Array)
        expect(result[:reviews].size).to eq(2)

        review_ratings = result[:reviews].map { |r| r[:rating] }
        expect(review_ratings).to match_array([5, 4])
      end
    end

    context "when no reviews exist for the book" do
      it "returns an empty array with default values" do
        result = ReviewService.show(book.id)

        expect(result).to include(:reviews, :average_rating, :total_reviews)
        expect(result[:reviews]).to eq([])
        expect(result[:average_rating]).to eq(0)
        expect(result[:total_reviews]).to eq(0)
      end
    end

    context "when an invalid book_id is provided" do
      it "returns an empty array with default values" do
        result = ReviewService.show(-1) # Invalid book_id

        expect(result).to include(:reviews, :average_rating, :total_reviews)
        expect(result[:reviews]).to eq([])
        expect(result[:average_rating]).to eq(0)
        expect(result[:total_reviews]).to eq(0)
      end
    end
  end

  describe ".destroy" do
    let!(:review) do
      ReviewService.create(
        user_id: user.id, book_id: book.id, rating: 5, comment: "Loved it!"
      )[:review]
    end

    context "when the review exists" do
      it "deletes the review successfully" do
        # Pass both review_id and user_id
        result = ReviewService.destroy(review["id"], user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Review deleted successfully")
        expect(Review.find_by(id: review["id"])).to be_nil
      end
    end

    context "when the review does not exist" do
      it "returns an error message" do
        result = ReviewService.destroy(-1, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Review not found or you don't have permission to delete it")
      end
    end

    context "when the review belongs to another user" do
      it "prevents deletion by unauthorized user" do
        result = ReviewService.destroy(review["id"], user2.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Review not found or you don't have permission to delete it")
      end
    end
  end
end