require 'rails_helper'

RSpec.describe Api::V1::ReviewsController, type: :controller do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "test@gmail.com",
      password: "Passw0rd!",
      mobile_number: "9876543210"
    )
  end
  let(:book) do
    Book.create!(
      name: "Test Book",
      author: "Test Author",
      mrp: 500.00,
      discounted_price: 450.00,
      quantity: 10
    )
  end
  let(:valid_review_params) do
    {
      review: {
        user_id: user.id,
        book_id: book.id,
        rating: 4,
        comment: "Great book!"
      }
    }
  end
  let(:invalid_review_params) do
    {
      review: {
        user_id: user.id,
        book_id: book.id,
        rating: nil, # Rating is required
        comment: "No rating provided"
      }
    }
  end

  before do
    # Mock Redis to avoid hitting an actual Redis instance during tests
    allow(REDIS).to receive(:del).and_return(true)
    allow(REDIS).to receive(:keys).and_return(["books:all:page1"])
  end

  after do
    # Clean up the database after each test
    Review.delete_all
    User.delete_all
    Book.delete_all
  end

  describe "POST #add_review" do
    context "when user is authenticated" do
      before do
        # Mock authenticate_request to simulate successful authentication
        allow(controller).to receive(:authenticate_request).and_return(true)
      end

      context "with valid parameters" do
        it "creates a new review and returns a success response" do
          post :add_review, params: valid_review_params, as: :json

          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Review added successfully")
          expect(json_response["review"]["rating"]).to eq(4)
          expect(json_response["review"]["comment"]).to eq("Great book!")
        end
      end

      context "with invalid parameters" do
        it "returns an error response" do
          post :add_review, params: invalid_review_params, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("Rating can't be blank")
        end
      end
    end

    context "when user is not authenticated" do
      before do
        # No need to mock authenticate_request; let it run and render its default response
      end

      it "does not allow access and returns unauthorized with 'Missing token'" do
        post :add_review, params: valid_review_params, as: :json
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing token")
      end
    end
  end

  describe "GET #get_reviews" do
    before do
      # Create test reviews manually
      Review.create!(user: user, book: book, rating: 5, comment: "Amazing!")
      Review.create!(
        user: User.create!(
          name: "Other User",
          email: "other@yahoo.com",
          password: "Secure123!",
          mobile_number: "8765432109"
        ),
        book: book,
        rating: 3,
        comment: "Okay"
      )
    end

    it "returns all reviews for a given book" do
      get :get_reviews, params: { book_id: book.id }, as: :json

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)["data"]
      expect(json_response["reviews"].count).to eq(2)
      expect(json_response["total_reviews"]).to eq(2)
      expect(json_response["average_rating"]).to eq(4.0) # (5 + 3) / 2 = 4.0
    end

    it "returns empty reviews when no reviews exist" do
      Review.delete_all # Clear reviews for this test
      get :get_reviews, params: { book_id: book.id }, as: :json

      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)["data"]
      expect(json_response["reviews"]).to be_empty
      expect(json_response["total_reviews"]).to eq(0)
      expect(json_response["average_rating"]).to eq(0)
    end
  end

  describe "DELETE #delete_review" do
    let(:review) { Review.create!(user: user, book: book, rating: 4, comment: "Nice book") }

    context "when user is authenticated" do
      before do
        # Mock authenticate_request to simulate successful authentication
        allow(controller).to receive(:authenticate_request).and_return(true)
      end

      context "when review exists and belongs to the user" do
        it "deletes the review and returns a success response" do
          delete :delete_review, params: { id: review.id, user_id: user.id }, as: :json

          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Review deleted successfully")
          expect(Review.exists?(review.id)).to be_falsey
        end
      end

      context "when review does not exist or does not belong to the user" do
        it "returns an error response" do
          delete :delete_review, params: { id: 999, user_id: user.id }, as: :json

          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to eq("Review not found or you don't have permission to delete it")
        end
      end
    end

    context "when user is not authenticated" do
      before do
        # No need to mock authenticate_request; let it run and render its default response
      end

      it "does not allow access and returns unauthorized with 'Missing token'" do
        delete :delete_review, params: { id: review.id, user_id: user.id }, as: :json
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing token")
      end
    end
  end
end