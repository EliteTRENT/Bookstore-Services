require 'rails_helper'

RSpec.describe Api::V1::WishlistsController, type: :controller do
  let(:user) do
    User.create!(
      name: "Test User",
      email: "test#{rand(1000)}@gmail.com", # Unique email to avoid duplicates
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

  let(:valid_token) do
    JsonWebToken.encode({ email: user.email }, 1.hour.from_now)
  end

  let(:invalid_token) { "invalid_token" }

  let(:valid_wishlist_params) do
    {
      wishlist: {
        book_id: book.id
      }
    }
  end

  # Stub token decoding and authentication for all tests
  before do
    # Stub invalid token to simulate JWT::DecodeError
    allow(JsonWebToken).to receive(:decode).with(invalid_token).and_return(nil)
    # Stub valid token to return a HashWithIndifferentAccess like the real decode method
    allow(JsonWebToken).to receive(:decode).with(valid_token).and_return(
      HashWithIndifferentAccess.new("email" => user.email, "exp" => 1.hour.from_now.to_i)
    )
    # Stub authenticate_request to set @current_user for valid token cases
    allow_any_instance_of(ApplicationController).to receive(:authenticate_request) do |controller|
      if request.headers["Authorization"] == "Bearer #{valid_token}"
        controller.instance_variable_set(:@current_user, user)
      else
        controller.render json: { error: "Missing token" }, status: :unauthorized
      end
    end
  end

  after do
    Wishlist.delete_all
    User.delete_all
    Book.delete_all
  end

  describe "POST #create" do
    context "with valid token and parameters" do
      it "adds a book to the wishlist and returns a success response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        post :create, params: valid_wishlist_params, as: :json

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Book added to wishlist!")
      end
    end

    context "with invalid token" do
      it "returns an unauthorized response" do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        post :create, params: valid_wishlist_params, as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing token")
      end
    end

    context "with valid token but non-existent book" do
      it "returns a not found response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        post :create, params: { wishlist: { book_id: 999 } }, as: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Book not found")
      end
    end
  end

  describe "GET #index" do
    let(:wishlist) { Wishlist.create!(user: user, book: book, is_deleted: false) }

    context "with valid token" do
      it "returns the user's wishlist" do
        wishlist # Ensure wishlist is created
        request.headers["Authorization"] = "Bearer #{valid_token}"
        get :index, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to be_a(Array)
        expect(json_response["message"].count).to eq(1)
        expect(json_response["message"].first["book_id"]).to eq(book.id)
      end
    end

    context "with invalid token" do
      it "returns an unauthorized response" do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        get :index, as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing token")
      end
    end

    context "with valid token but no wishlist items" do
      it "returns an empty wishlist" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        get :index, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to be_a(Array)
        expect(json_response["message"]).to be_empty
      end
    end
  end

  describe "PATCH #mark_book_as_deleted" do
    let(:wishlist) { Wishlist.create!(user: user, book: book, is_deleted: false) }

    context "with valid token and existing wishlist item" do
      it "marks the wishlist item as deleted and returns a success response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        patch :mark_book_as_deleted, params: { wishlist_id: wishlist.id }, as: :json

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Book removed from wishlist!")
        expect(wishlist.reload.is_deleted).to be true
      end
    end

    context "with invalid token" do
      it "returns an unauthorized response" do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        patch :mark_book_as_deleted, params: { wishlist_id: wishlist.id }, as: :json

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing token")
      end
    end

    context "with valid token but non-existent wishlist item" do
      it "returns a not found response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        patch :mark_book_as_deleted, params: { wishlist_id: 999 }, as: :json

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to eq("Wishlist item not found")
      end
    end
  end
end