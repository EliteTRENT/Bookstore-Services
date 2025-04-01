require 'rails_helper'

RSpec.describe Api::V1::BooksController, type: :controller do
  let(:user) { User.create!(name: "Test User", email: "test@gmail.com", password: "Password@123", mobile_number: "9876543210") }
  let(:admin_user) { User.create!(name: "Admin", email: "admin@gmail.com", password: "Password@123", mobile_number: "9876543210", role: "admin") } # Valid mobile number
  let(:valid_token) { JsonWebToken.encode({ user_id: user.id }) }
  let(:admin_token) { JsonWebToken.encode({ user_id: admin_user.id }) }
  let(:invalid_token) { "invalid.token.here" }

  before do
    # Mock Redis for caching
    allow(REDIS).to receive(:get).and_return(nil)
    allow(REDIS).to receive(:setex)
    allow(REDIS).to receive(:del)
    allow(REDIS).to receive(:keys).and_return([])
  end

  describe "POST #create" do
    context "with authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{admin_token}"
        allow(controller).to receive(:authenticate_request).and_return(true)
        allow(controller).to receive(:restrict_to_admin).and_return(true)
      end

      context "with valid single book attributes" do
        let(:valid_book_params) do
          {
            book: {
              name: "Test Book",
              author: "Test Author",
              mrp: 100,
              discounted_price: 80,
              quantity: 10,
              book_details: "A test book",
              genre: "Fiction"
            }
          }
        end

        it "creates a book and returns a success response" do
          post :create, params: valid_book_params
          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Book created successfully")
          expect(json_response["book"]["name"]).to eq("Test Book")
          expect(Book.count).to eq(1)
        end
      end

      context "with invalid single book attributes" do
        let(:invalid_book_params) do
          {
            book: {
              name: "", # Invalid: name is blank
              author: "Test Author",
              mrp: 100,
              discounted_price: 80,
              quantity: 10
            }
          }
        end

        it "returns an error response" do
          post :create, params: invalid_book_params
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("Name can't be blank")
        end
      end

      context "with valid CSV file" do
        let(:csv_params) { { books: "mocked_csv_file" } }
        let(:mocked_books) do
          [
            Book.new(name: "Book 1", author: "Author 1", mrp: 100, discounted_price: 80, quantity: 10, book_details: "Details 1", genre: "Fiction")
          ]
        end

        before do
          allow(BookService).to receive(:create_book).with(file: "mocked_csv_file").and_return(
            { success: true, message: "Books created successfully from CSV", books: mocked_books }
          )
        end

        it "creates books from CSV and returns a success response" do
          post :create, params: csv_params
          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Books created successfully from CSV")
          expect(json_response["books"].length).to eq(1)
          expect(json_response["books"].first["name"]).to eq("Book 1")
        end
      end
    end

    context "without authentication" do
      before { request.headers["Authorization"] = nil }

      it "returns an unauthorized response" do
        post :create, params: { book: { name: "Test Book" } }
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to eq("Missing token")
      end
    end
  end

  describe "PUT #update" do
    let!(:book) { FactoryBot.create(:book) }

    context "with authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{admin_token}"
        allow(controller).to receive(:authenticate_request).and_return(true)
        allow(controller).to receive(:restrict_to_admin).and_return(true)
      end

      context "with valid attributes" do
        let(:update_params) { { id: book.id, book: { name: "Updated Book" } } }

        it "updates the book and returns a success response" do
          put :update, params: update_params
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Book updated successfully")
          expect(json_response["book"]["name"]).to eq("Updated Book")
        end
      end

      context "with invalid attributes" do
        let(:invalid_update_params) { { id: book.id, book: { name: "" } } }

        it "returns an error response" do
          put :update, params: invalid_update_params
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["errors"]).to include("Name can't be blank")
        end
      end

      context "with non-existent book" do
        it "returns an error response" do
          put :update, params: { id: 999, book: { name: "New Name" } }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)["errors"]).to eq("Book not found or has been deleted")
        end
      end
    end
  end

  describe "GET #index" do
    let!(:books) { 15.times { FactoryBot.create(:book) } }

    it "returns a paginated list of books" do
      get :index, params: { page: 1, per_page: 10 }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["message"]).to eq("Books retrieved successfully")
      expect(json_response["books"].length).to eq(10)
      expect(json_response["pagination"]["total_count"]).to eq(15)
      expect(json_response["pagination"]["total_pages"]).to eq(2)
    end

    context "with sorting" do
      let!(:cheap_book) { FactoryBot.create(:book, discounted_price: 10.0) }

      it "sorts by price low to high" do
        get :index, params: { sort_by: "price-low" }
        json_response = JSON.parse(response.body)
        expect(json_response["books"].first["discounted_price"].to_f).to eq(10.0)
      end
    end
  end

  describe "GET #show" do
    let!(:book) { FactoryBot.create(:book) }

    it "returns the book details" do
      get :show, params: { id: book.id }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["message"]).to eq("Book retrieved successfully")
      expect(json_response["book"]["name"]).to eq(book.name)
    end

    context "with non-existent book" do
      it "returns an error response" do
        get :show, params: { id: 999 }
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)["errors"]).to eq("Book not found or has been deleted")
      end
    end
  end

  describe "PATCH #toggle_delete" do
    let!(:book) { FactoryBot.create(:book) }

    context "with authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{admin_token}"
        allow(controller).to receive(:authenticate_request).and_return(true)
        allow(controller).to receive(:restrict_to_admin).and_return(true)
      end

      it "toggles the book deletion status" do
        patch :toggle_delete, params: { id: book.id }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Book marked as deleted")
        expect(book.reload.is_deleted).to be true
      end

      context "with non-existent book" do
        it "returns an error response" do
          patch :toggle_delete, params: { id: 999 }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)["errors"]).to eq("Book not found")
        end
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:book) { FactoryBot.create(:book) }

    context "with authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request).and_return(true)
      end

      it "permanently deletes the book" do
        delete :destroy, params: { id: book.id }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Book permanently deleted")
        expect(Book.find_by(id: book.id)).to be_nil
      end

      context "with non-existent book" do
        it "returns an error response" do
          delete :destroy, params: { id: 999 }
          expect(response).to have_http_status(:not_found)
          expect(JSON.parse(response.body)["errors"]).to eq("Book not found")
        end
      end
    end
  end

  describe "GET #search_suggestions" do
    let!(:book) { FactoryBot.create(:book, name: "Test Book", author: "Test Author") }

    it "returns search suggestions" do
      get :search_suggestions, params: { query: "Test" }
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response["message"]).to eq("Search suggestions retrieved successfully")
      expect(json_response["suggestions"].length).to eq(1)
      expect(json_response["suggestions"].first["name"]).to eq("Test Book")
    end

    context "with blank query" do
      it "returns an error response" do
        get :search_suggestions, params: { query: "" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["errors"]).to eq("Query parameter is required")
      end
    end
  end

  describe "GET #stock" do
    let!(:book1) { FactoryBot.create(:book, quantity: 5) }
    let!(:book2) { FactoryBot.create(:book, quantity: 3) }

    context "with authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request).and_return(true)
      end

      it "returns stock for given book IDs" do
        get :stock, params: { book_ids: "#{book1.id},#{book2.id}" }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["stock"].length).to eq(2)
        expect(json_response["stock"].first["quantity"]).to eq(5)
      end

      context "with missing book_ids" do
        it "returns an error response" do
          get :stock
          expect(response).to have_http_status(:bad_request)
          expect(JSON.parse(response.body)["error"]).to eq("book_ids parameter is required")
        end
      end

      context "with non-existent book IDs" do
        it "returns an error response" do
          get :stock, params: { book_ids: "999" }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(JSON.parse(response.body)["error"]).to eq("No books found for the given IDs")
        end
      end
    end
  end
end