require 'rails_helper'

RSpec.describe ReviewService, type: :service do
  let!(:user) { User.create!(name: "John Doe", email: "john.doe@gmail.com", password: "Password@123", mobile_number: "9876543210") }
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
end
