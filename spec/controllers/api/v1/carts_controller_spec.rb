require 'rails_helper'

RSpec.describe Api::V1::CartsController, type: :controller do
  let(:user) { User.create!(name: "Test User", email: "test@gmail.com", password: "Password@123", mobile_number: "9876543210") }
  let(:book) { Book.create!(name: "Test Book", author: "Author", mrp: 100, discounted_price: 80, quantity: 10) }
  let(:valid_token) { JsonWebToken.encode({ id: user.id, email: user.email }) }
  let(:invalid_token) { "invalid.token.here" }

  describe "POST #add_book" do
    context "with authentication" do
      before { request.headers["Authorization"] = "Bearer #{valid_token}" }

      context "with valid cart parameters" do
        let(:valid_cart_params) do
          {
            cart: {
              user_id: user.id,
              book_id: book.id,
              quantity: 2
            }
          }
        end

        it "adds a new book to the cart and returns a success response" do
          # Stub with hash_including to match ActionController::Parameters
          allow(CartService).to receive(:add_book).with(hash_including(
            "user_id" => user.id.to_s,
            "book_id" => book.id.to_s,
            "quantity" => "2"
          )).and_return(
            { success: true, message: "Book added to cart", cart: Cart.new(user_id: user.id, book_id: book.id, quantity: 2) }
          )
          post :add_book, params: valid_cart_params
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Book added to cart")
          expect(json_response["cart"]["user_id"]).to eq(user.id)
          expect(json_response["cart"]["book_id"]).to eq(book.id)
          expect(json_response["cart"]["quantity"]).to eq(2)
        end
      end

      context "with invalid quantity" do
        let(:invalid_cart_params) do
          {
            cart: {
              user_id: user.id,
              book_id: book.id,
              quantity: 0
            }
          }
        end

        it "returns an error response" do
          allow(CartService).to receive(:add_book).with(hash_including(
            "user_id" => user.id.to_s,
            "book_id" => book.id.to_s,
            "quantity" => "0"
          )).and_return(
            { success: false, error: "Invalid quantity" }
          )
          post :add_book, params: invalid_cart_params
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Invalid quantity")
        end
      end
    end

    context "without authentication" do
      it "returns an unauthorized response" do
        post :add_book, params: { cart: { user_id: user.id, book_id: book.id, quantity: 2 } }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Missing token")
      end
    end
  end

  describe "GET #get_cart" do
    context "with authentication" do
      before { request.headers["Authorization"] = "Bearer #{valid_token}" }

      context "with items in the cart" do
        let(:cart_data) do
          [
            { cart_id: 1, book_id: book.id, book_name: book.name, author_name: book.author, quantity: 2, price: book.discounted_price, image_url: book.book_image }
          ]
        end

        it "returns the cart contents" do
          allow(CartService).to receive(:get_cart).with(user.id.to_s).and_return(
            { success: true, message: "Cart retrieved successfully", cart: cart_data }
          )
          get :get_cart, params: { user_id: user.id }
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Cart retrieved successfully")
          expect(json_response["cart"].length).to eq(1)
          expect(json_response["cart"].first["book_name"]).to eq("Test Book")
        end
      end

      context "with an empty cart" do
        it "returns an empty cart response" do
          allow(CartService).to receive(:get_cart).with(user.id.to_s).and_return(
            { success: true, message: "Cart is empty", cart: [] }
          )
          get :get_cart, params: { user_id: user.id }
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Cart is empty")
          expect(json_response["cart"]).to be_empty
        end
      end

      context "when an error occurs" do
        it "returns an error response" do
          allow(CartService).to receive(:get_cart).with(user.id.to_s).and_return(
            { success: false, error: "Error retrieving cart: Database error" }
          )
          get :get_cart, params: { user_id: user.id }
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Error retrieving cart: Database error")
        end
      end
    end
  end

  describe "DELETE #soft_delete_book" do
    context "with authentication" do
      before { request.headers["Authorization"] = "Bearer #{valid_token}" }

      context "with a valid cart item" do
        let(:cart_item) { Cart.new(user_id: user.id, book_id: book.id, quantity: 2, is_deleted: true) }

        it "soft deletes the book from the cart" do
          allow(CartService).to receive(:soft_delete_book).with(book.id.to_s, user.id).and_return(
            { success: true, message: "Book removed from cart", book: cart_item }
          )
          delete :soft_delete_book, params: { id: book.id }
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Book removed from cart")
          expect(json_response["book"]["book_id"]).to eq(book.id)
        end
      end

      context "with a non-existent cart item" do
        it "returns a not found response" do
          allow(CartService).to receive(:soft_delete_book).with("999", user.id).and_return(
            { success: false, error: "Cart item not found" }
          )
          delete :soft_delete_book, params: { id: 999 }
          expect(response).to have_http_status(:not_found)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Cart item not found")
        end
      end

      context "with an error during deletion" do
        it "returns an unprocessable entity response" do
          allow(CartService).to receive(:soft_delete_book).with(book.id.to_s, user.id).and_return(
            { success: false, error: "Error updating cart item: Database error" }
          )
          delete :soft_delete_book, params: { id: book.id }
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Error updating cart item: Database error")
        end
      end
    end

    context "with invalid authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        # Mock JsonWebToken.decode to raise a DecodeError for invalid token
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_raise(JWT::DecodeError, "Invalid token")
      end

      it "returns an unauthorized response" do
        delete :soft_delete_book, params: { id: book.id }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Session expired")
      end
    end
  end

  describe "PATCH #update_quantity" do
    context "with authentication" do
      before { request.headers["Authorization"] = "Bearer #{valid_token}" }

      context "with valid quantity update" do
        let(:update_params) do
          {
            cart: {
              book_id: book.id,
              quantity: 3
            }
          }
        end

        it "updates the cart quantity and returns a success response" do
          allow(CartService).to receive(:update_quantity).with(hash_including(
            "book_id" => book.id.to_s,
            "quantity" => "3"
          ), user.id).and_return(
            { success: true, message: "Cart quantity updated", cart: Cart.new(user_id: user.id, book_id: book.id, quantity: 3) }
          )
          patch :update_quantity, params: update_params
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["success"]).to be true
          expect(json_response["message"]).to eq("Cart quantity updated")
          expect(json_response["cart"]["quantity"]).to eq(3)
        end
      end

      context "with invalid quantity" do
        let(:invalid_params) do
          {
            cart: {
              book_id: book.id,
              quantity: 0
            }
          }
        end

        it "returns an error response" do
          allow(CartService).to receive(:update_quantity).with(hash_including(
            "book_id" => book.id.to_s,
            "quantity" => "0"
          ), user.id).and_return(
            { success: false, error: "Invalid quantity" }
          )
          patch :update_quantity, params: invalid_params
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["success"]).to be false
          expect(json_response["error"]).to eq("Invalid quantity")
        end
      end

      context "with non-existent cart item" do
        let(:update_params) do
          {
            cart: {
              book_id: 999,
              quantity: 3
            }
          }
        end

        it "returns an error response" do
          allow(CartService).to receive(:update_quantity).with(hash_including(
            "book_id" => "999",
            "quantity" => "3"
          ), user.id).and_return(
            { success: false, error: "Cart item not found" }
          )
          patch :update_quantity, params: update_params
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["success"]).to be false
          expect(json_response["error"]).to eq("Cart item not found")
        end
      end
    end

    context "with invalid authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_raise(JWT::DecodeError, "Invalid token")
      end

      it "returns an unauthorized response" do
        patch :update_quantity, params: { cart: { book_id: book.id, quantity: 3 } }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Session expired")
      end
    end
  end
end