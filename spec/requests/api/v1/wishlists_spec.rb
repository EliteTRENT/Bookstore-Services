require 'rails_helper'

RSpec.describe "Wishlists API", type: :request do
  let!(:user) { User.create!(name: "Test User", email: "test1234@gmail.com", password: "Password@1234", mobile_number: 7087077804) }
  let!(:book) {
  Book.create!(
    name: "Test Book",
    author: "Author Name",
    mrp: 500,
    discounted_price: 450,
    quantity: 10
  )
}
  let(:token) { JsonWebToken.encode(email: user.email) }

  describe "POST /api/v1/wishlists/add" do
    context "with a valid book and token" do
      it "adds the book to the wishlist and returns a success message" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: book.id } },
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["message"]).to eq("Book added to wishlist!")
        expect(user.wishlists.exists?(book_id: book.id, is_deleted: false)).to be true
      end
    end

    context "when the book is already in the wishlist" do
      before { user.wishlists.create(book: book, is_deleted: false) }

      it "returns an error message indicating the book is already in the wishlist" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: book.id } },
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to include("Book is already in your wishlist")
      end
    end

    context "without an authorization token" do
      it "returns an invalid token error" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: book.id } }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid token")
      end
    end

    context "with an invalid token" do
      it "returns an invalid token error" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: book.id } },
             headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid token")
      end
    end

    context "with a token for a non-existent user" do
      let(:fake_token) { JsonWebToken.encode(email: "fake_user@gmail.com") }

      it "returns a user not found error" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: book.id } },
             headers: { "Authorization" => "Bearer #{fake_token}" }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("User not found")
      end
    end

    context "with a non-existent book" do
      it "returns a book not found error" do
        post "/api/v1/wishlists/add",
             params: { wishlist: { book_id: 9999 } },
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("Book not found")
      end
    end
  end

  describe "GET /api/v1/wishlists/getAll" do
    context "with a valid token and existing wishlist items" do
      before { user.wishlists.create(book: book, is_deleted: false) }

      it "returns all active wishlisted books" do
        get "/api/v1/wishlists/getAll", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["message"]).to be_an(Array)
        expect(body["message"].first["book_id"]).to eq(book.id)
      end
    end

    context "without an authorization token" do
      it "returns an invalid token error" do
        get "/api/v1/wishlists/getAll"

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid token")
      end
    end

    context "with an invalid token" do
      it "returns an invalid token error" do
        get "/api/v1/wishlists/getAll", headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid token")
      end
    end

    context "with a token for a non-existent user" do
      let(:fake_token) { JsonWebToken.encode(email: "fake_user@gmail.com") }

      it "returns a user not found error" do
        get "/api/v1/wishlists/getAll", headers: { "Authorization" => "Bearer #{fake_token}" }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("User not found")
      end
    end

    context "with an empty wishlist" do
      it "returns an empty array" do
        get "/api/v1/wishlists/getAll", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["message"]).to eq([])
      end
    end
  end

  describe "DELETE /api/v1/wishlists/destroy/{book_id}" do
    context "with a valid token and book in the wishlist" do
      before { user.wishlists.create(book: book, is_deleted: false) }

      it "marks the book as deleted in the wishlist and returns a success message" do
        delete "/api/v1/wishlists/destroy/#{book.id}",
               headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["message"]).to eq("Book removed from wishlist!")
        expect(user.wishlists.exists?(book_id: book.id, is_deleted: false)).to be false
        expect(user.wishlists.find_by(book_id: book.id, is_deleted: true)).to be_present
      end
    end

    context "with a valid token but book not in the wishlist" do
      it "returns an error message indicating the book is not in the wishlist" do
        delete "/api/v1/wishlists/destroy/#{book.id}",
               headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["errors"]).to eq("Book not found in wishlist")
      end
    end

    context "with a non-existent book" do
      it "returns an error indicating the book is not in the wishlist" do
        delete "/api/v1/wishlists/destroy/9999",
               headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["errors"]).to eq("Book not found in wishlist")
      end
    end

    context "without an authorization token" do
      it "returns an invalid token error" do
        delete "/api/v1/wishlists/destroy/#{book.id}"

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid token")
      end
    end

    context "with an invalid token" do
      it "returns an invalid token error" do
        delete "/api/v1/wishlists/destroy/#{book.id}",
               headers: { "Authorization" => "Bearer invalid_token" }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Invalid token")
      end
    end

    context "with a token for a non-existent user" do
      let(:fake_token) { JsonWebToken.encode(email: "fake_user@gmail.com") }

      it "returns a user not found error" do
        delete "/api/v1/wishlists/destroy/#{book.id}",
               headers: { "Authorization" => "Bearer #{fake_token}" }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["error"]).to eq("User not found")
      end
    end
  end
end
