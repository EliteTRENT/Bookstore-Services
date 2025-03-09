require 'rails_helper'

RSpec.describe "Wishlists API", type: :request do
  let!(:user) { User.create!(name: "Test User", email: "test1234@gmail.com", password: "Password@1234", mobile_number: 7087077804) }
  let!(:book) { Book.create!(name: "Test Book", author: "Author Name") }
  let(:token) { JsonWebToken.encode(email: user.email) }

  describe "POST /api/v1/wishlists/add" do
    context "when adding a valid book to the wishlist" do
      it "returns success message" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: book.id } },
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["message"]).to eq("Book added to wishlist!")
        expect(user.wishlists.exists?(book_id: book.id)).to be true
      end
    end

    context "when the book is already in the wishlist" do
      before { user.wishlists.create(book: book) }

      it "returns an error message" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: book.id } },
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Book is already in your wishlist")
      end
    end

    context "when token is missing" do
      it "returns an unauthorized status" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: book.id } }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when token is invalid" do
      it "returns an invalid token error" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: book.id } },
             headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid token")
      end
    end

    context "when user is not found" do
      let(:fake_token) { JsonWebToken.encode(email: "fake_user@gmail.com") } # Encode email instead of user_id

      it "returns a user not found error" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: book.id } },
             headers: { "Authorization" => "Bearer #{fake_token}" }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("User not found")
      end
    end

    context "when book is not found" do
      it "returns a book not found error" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: 9999 } }, # Non-existent book ID
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("Book not found")
      end
    end
  end

  describe "GET /api/v1/wishlists/getAll" do
    context "when request is valid" do
      before { user.wishlists.create(book: book) }
      it "returns all wishlisted books" do
        get "/api/v1/wishlists/getAll", headers: { "Authorization" => "Bearer #{token}" }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["message"]).to be_an(Array)
        expect(body["message"].first["book_id"]).to eq(book.id) 
      end
    end

    context "when token is missing" do
      it "returns unauthorized status" do
        get "/api/v1/wishlists/getAll"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when token is invalid" do
      it "returns invalid token error" do
        get "/api/v1/wishlists/getAll", headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid token")
      end
    end

    context "when user is not found" do
      let(:fake_token) { JsonWebToken.encode(email: "fake_user@gmail.com") }

      it "returns a user not found error" do
        get "/api/v1/wishlists/getAll", headers: { "Authorization" => "Bearer #{fake_token}" }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("User not found")
      end
    end

    context "when wishlist is empty" do
      it "returns an empty array" do
        get "/api/v1/wishlists/getAll", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["message"]).to eq([])
      end
    end
  end
end
