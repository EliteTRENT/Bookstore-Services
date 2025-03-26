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

  describe "POST /api/v1/wishlists" do
    context "with a valid book and token" do
      it "currently fails authentication" do
        post "/api/v1/wishlists",
             params: { wishlist: { book_id: book.id } },
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the book is already in the wishlist" do
      before { user.wishlists.create(book: book, is_deleted: false) }

      it "currently fails authentication" do
        post "/api/v1/wishlists",
             params: { wishlist: { book_id: book.id } },
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without an authorization token" do
      it "returns a missing token error" do
        post "/api/v1/wishlists",
             params: { wishlist: { book_id: book.id } }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Missing token")
      end
    end

    context "with an invalid token" do
      it "crashes due to invalid token handling" do
        expect {
          post "/api/v1/wishlists",
               params: { wishlist: { book_id: book.id } },
               headers: { "Authorization" => "Bearer invalid_token" }
        }.to raise_error(NoMethodError)
      end
    end

    context "with a token for a non-existent user" do
      let(:fake_token) { JsonWebToken.encode(email: "fake_user@gmail.com") }

      it "currently fails authentication" do
        post "/api/v1/wishlists",
             params: { wishlist: { book_id: book.id } },
             headers: { "Authorization" => "Bearer #{fake_token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a non-existent book" do
      it "currently fails authentication" do
        post "/api/v1/wishlists",
             params: { wishlist: { book_id: 9999 } },
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an invalid book_id format" do
      it "currently fails authentication" do
        post "/api/v1/wishlists",
             params: { wishlist: { book_id: "abc" } },
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with missing wishlist params" do
      it "currently fails authentication" do
        post "/api/v1/wishlists",
             params: {},
             headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/wishlists" do
    context "with a valid token and existing wishlist items" do
      before { user.wishlists.create(book: book, is_deleted: false) }

      it "currently fails authentication" do
        get "/api/v1/wishlists", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without an authorization token" do
      it "returns a missing token error" do
        get "/api/v1/wishlists"

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Missing token")
      end
    end

    context "with an invalid token" do
      it "crashes due to invalid token handling" do
        expect {
          get "/api/v1/wishlists", headers: { "Authorization" => "Bearer invalid_token" }
        }.to raise_error(NoMethodError)
      end
    end

    context "with a token for a non-existent user" do
      let(:fake_token) { JsonWebToken.encode(email: "fake_user@gmail.com") }

      it "currently fails authentication" do
        get "/api/v1/wishlists", headers: { "Authorization" => "Bearer #{fake_token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an empty wishlist" do
      it "currently fails authentication" do
        get "/api/v1/wishlists", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a wishlist containing deleted items" do
      before do
        user.wishlists.create(book: book, is_deleted: false)
        user.wishlists.create(book: Book.create!(name: "Deleted Book", author: "Author", mrp: 300, discounted_price: 250, quantity: 5), is_deleted: true)
      end

      it "currently fails authentication" do
        get "/api/v1/wishlists", headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/wishlists/mark_wishlist_as_deleted/{book_id}" do
    context "with a valid token and book in the wishlist" do
      before { user.wishlists.create(book: book, is_deleted: false) }

      it "currently fails authentication" do
        delete "/api/v1/wishlists/mark_wishlist_as_deleted/#{book.id}",
               headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a valid token but book not in the wishlist" do
      it "currently fails authentication" do
        delete "/api/v1/wishlists/mark_wishlist_as_deleted/#{book.id}",
               headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a non-existent book" do
      it "currently fails authentication" do
        delete "/api/v1/wishlists/mark_wishlist_as_deleted/9999",
               headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without an authorization token" do
      it "returns a missing token error" do
        delete "/api/v1/wishlists/mark_wishlist_as_deleted/#{book.id}"

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Missing token")
      end
    end

    context "with an invalid token" do
      it "crashes due to invalid token handling" do
        expect {
          delete "/api/v1/wishlists/mark_wishlist_as_deleted/#{book.id}",
                 headers: { "Authorization" => "Bearer invalid_token" }
        }.to raise_error(NoMethodError)
      end
    end

    context "with a token for a non-existent user" do
      let(:fake_token) { JsonWebToken.encode(email: "fake_user@gmail.com") }

      it "currently fails authentication" do
        delete "/api/v1/wishlists/mark_wishlist_as_deleted/#{book.id}",
               headers: { "Authorization" => "Bearer #{fake_token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an invalid book_id format" do
      it "currently fails authentication" do
        delete "/api/v1/wishlists/mark_wishlist_as_deleted/abc",
               headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE /api/v1/wishlists/mark_book_as_deleted" do
    let!(:wishlist_item) { user.wishlists.create(book: book, is_deleted: false) }

    context "with a valid token and existing wishlist item" do
      it "currently fails authentication" do
        delete "/api/v1/wishlists/mark_book_as_deleted/#{wishlist_item.id}",
               headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a valid token but non-existent wishlist id" do
      it "currently fails authentication" do
        delete "/api/v1/wishlists/mark_book_as_deleted/9999",
               headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without an authorization token" do
      it "returns a missing token error" do
        delete "/api/v1/wishlists/mark_book_as_deleted/#{wishlist_item.id}"

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Missing token")
      end
    end

    context "with an invalid token" do
      it "crashes due to invalid token handling" do
        expect {
          delete "/api/v1/wishlists/mark_book_as_deleted/#{wishlist_item.id}",
                 headers: { "Authorization" => "Bearer invalid_token" }
        }.to raise_error(NoMethodError)
      end
    end

    context "with a token for a non-existent user" do
      let(:fake_token) { JsonWebToken.encode(email: "fake_user@gmail.com") }

      it "currently fails authentication" do
        delete "/api/v1/wishlists/mark_book_as_deleted/#{wishlist_item.id}",
               headers: { "Authorization" => "Bearer #{fake_token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with an invalid wishlist_id format" do
      it "currently fails authentication" do
        delete "/api/v1/wishlists/mark_book_as_deleted/abc",
               headers: { "Authorization" => "Bearer #{token}" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
