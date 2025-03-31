require 'rails_helper'

RSpec.describe BookService, type: :request do
  # Setup Redis mock for testing, allowing only the methods used in BookService
  let(:redis) { double(:redis) }
  before do
    stub_const("BookService::REDIS", redis)
    allow(redis).to receive(:get).and_return(nil)
    allow(redis).to receive(:setex)
    allow(redis).to receive(:del)
    allow(redis).to receive(:keys).and_return([])
  end

  describe ".create_book" do
    context "with valid attributes" do
      let(:valid_attributes) { attributes_for(:book) }

      it "creates a book successfully" do
        result = BookService.create_book(valid_attributes)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book created successfully")
        expect(result[:book]).to be_a(Book)
        expect(result[:book].persisted?).to be_truthy
        expect(result[:book].name).to eq(valid_attributes[:name])
        expect(result[:book].author).to eq(valid_attributes[:author])
        expect(result[:book].mrp).to eq(valid_attributes[:mrp])
        expect(result[:book].discounted_price).to eq(valid_attributes[:discounted_price])
        expect(result[:book].quantity).to eq(valid_attributes[:quantity])
      end

      it "creates a book successfully with only required fields" do
        minimal_attributes = attributes_for(:book, book_details: nil, genre: nil, book_image: nil)
        result = BookService.create_book(minimal_attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].persisted?).to be_truthy
      end

      it "invalidates Redis cache for all books" do
        expect(redis).to receive(:keys).with("books:all:*").and_return(["books:all:1:10"])
        expect(redis).to receive(:del).with("books:all:1:10")
        BookService.create_book(valid_attributes)
      end
    end

    context "with invalid attributes" do
      let(:valid_attributes) { attributes_for(:book) }

      it "returns an error when name is missing" do
        invalid_attributes = attributes_for(:book, :missing_name)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Name can't be blank")
      end

      it "returns an error when name is nil" do
        invalid_attributes = attributes_for(:book, :nil_name)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Name can't be blank")
      end

      it "returns an error when author is missing" do
        invalid_attributes = attributes_for(:book, :missing_author)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Author can't be blank")
      end

      it "returns an error when author is nil" do
        invalid_attributes = attributes_for(:book, :nil_author)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Author can't be blank")
      end

      it "returns an error when mrp is missing" do
        invalid_attributes = attributes_for(:book, :nil_mrp)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Mrp can't be blank")
      end

      it "returns an error when mrp is negative" do
        invalid_attributes = attributes_for(:book, :negative_mrp)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Mrp must be greater than or equal to 0")
      end

      it "returns an error when mrp is not a number" do
        invalid_attributes = attributes_for(:book, :invalid_mrp)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Mrp is not a number")
      end

      it "returns an error when discounted_price is missing" do
        invalid_attributes = attributes_for(:book, :nil_discounted_price)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Discounted price can't be blank")
      end

      it "returns an error when discounted_price is negative" do
        invalid_attributes = attributes_for(:book, :negative_discounted_price)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Discounted price must be greater than or equal to 0")
      end

      it "returns an error when discounted_price is not a number" do
        invalid_attributes = attributes_for(:book, :invalid_discounted_price)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Discounted price is not a number")
      end

      it "returns an error when quantity is missing" do
        invalid_attributes = attributes_for(:book, :nil_quantity)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Quantity can't be blank")
      end

      it "returns an error when quantity is negative" do
        invalid_attributes = attributes_for(:book, :negative_quantity)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Quantity must be greater than or equal to 0")
      end

      it "returns an error when quantity is not an integer" do
        invalid_attributes = attributes_for(:book, :non_integer_quantity)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Quantity must be an integer")
      end

      it "returns an error when quantity is a string" do
        invalid_attributes = attributes_for(:book, :invalid_quantity)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Quantity is not a number")
      end

      it "accepts valid book_details when provided" do
        attributes = attributes_for(:book, book_details: "A detailed description")
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].book_details).to eq("A detailed description")
      end

      it "accepts nil book_details" do
        attributes = attributes_for(:book, book_details: nil)
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].book_details).to be_nil
      end

      it "accepts valid genre when provided" do
        attributes = attributes_for(:book, genre: "Fiction")
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].genre).to eq("Fiction")
      end

      it "accepts nil genre" do
        attributes = attributes_for(:book, genre: nil)
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].genre).to be_nil
      end

      it "accepts valid book_image when provided" do
        attributes = attributes_for(:book, book_image: "http://example.com/image.jpg")
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].book_image).to eq("http://example.com/image.jpg")
      end

      it "accepts nil book_image" do
        attributes = attributes_for(:book, book_image: nil)
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].book_image).to be_nil
      end

      it "returns multiple errors when multiple validations fail" do
        invalid_attributes = attributes_for(:book, :missing_name, :missing_author, :negative_mrp, :negative_discounted_price, :negative_quantity)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Name can't be blank")
        expect(result[:error]).to include("Author can't be blank")
        expect(result[:error]).to include("Mrp must be greater than or equal to 0")
        expect(result[:error]).to include("Discounted price must be greater than or equal to 0")
        expect(result[:error]).to include("Quantity must be greater than or equal to 0")
      end
    end
  end

  describe ".update_book" do
    let(:book) { create(:book) }

    context "with existing book" do
      context "with valid updates" do
        it "updates all attributes successfully" do
          update_attributes = attributes_for(:book, name: "Updated Title", author: "Updated Author", mrp: 25.99, discounted_price: 19.99, quantity: 50, book_details: "Updated details", genre: "Non-Fiction", book_image: "http://example.com/new-cover.jpg")
          expect(redis).to receive(:keys).with("books:all:*").and_return(["books:all:1:10"])
          expect(redis).to receive(:del).with("books:all:1:10")
          expect(redis).to receive(:del).with("book:#{book.id}")
          result = BookService.update_book(book.id, update_attributes)
          expect(result[:success]).to be_truthy
          expect(result[:message]).to eq("Book updated successfully")
          expect(result[:book].name).to eq("Updated Title")
          expect(result[:book].author).to eq("Updated Author")
          expect(result[:book].mrp).to eq(25.99)
          expect(result[:book].discounted_price).to eq(19.99)
          expect(result[:book].quantity).to eq(50)
          expect(result[:book].book_details).to eq("Updated details")
          expect(result[:book].genre).to eq("Non-Fiction")
          expect(result[:book].book_image).to eq("http://example.com/new-cover.jpg")
        end

        it "updates partial attributes successfully" do
          update_attributes = { name: "New Title", quantity: 75 }
          expect(redis).to receive(:keys).with("books:all:*").and_return(["books:all:1:10"])
          expect(redis).to receive(:del).with("books:all:1:10")
          expect(redis).to receive(:del).with("book:#{book.id}")
          result = BookService.update_book(book.id, update_attributes)
          expect(result[:success]).to be_truthy
          expect(result[:book].name).to eq("New Title")
          expect(result[:book].quantity).to eq(75)
          expect(result[:book].author).to eq(book.author)
          expect(result[:book].mrp).to eq(book.mrp)
        end
      end

      context "with invalid updates" do
        it "fails when name is blank" do
          result = BookService.update_book(book.id, { name: "" })
          expect(result[:success]).to be_falsey
          expect(result[:error]).to include("Name can't be blank")
        end

        it "fails when mrp is negative" do
          result = BookService.update_book(book.id, { mrp: -1 })
          expect(result[:success]).to be_falsey
          expect(result[:error]).to include("Mrp must be greater than or equal to 0")
        end

        it "fails when discounted_price is negative" do
          result = BookService.update_book(book.id, { discounted_price: -1 })
          expect(result[:success]).to be_falsey
          expect(result[:error]).to include("Discounted price must be greater than or equal to 0")
        end

        it "fails when quantity is negative" do
          result = BookService.update_book(book.id, { quantity: -1 })
          expect(result[:success]).to be_falsey
          expect(result[:error]).to include("Quantity must be greater than or equal to 0")
        end

        it "fails when quantity is not an integer" do
          result = BookService.update_book(book.id, { quantity: 5.5 })
          expect(result[:success]).to be_falsey
          expect(result[:error]).to include("Quantity must be an integer")
        end
      end
    end

    context "with non-existent book" do
      it "returns error when book doesn't exist" do
        result = BookService.update_book(999, { name: "New Title" })
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found or has been deleted")
      end
    end

    context "with deleted book" do
      let(:deleted_book) { create(:book, :deleted) }

      it "returns error when book is deleted" do
        result = BookService.update_book(deleted_book.id, { name: "New Title" })
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found or has been deleted")
      end
    end
  end

  describe ".index_books" do
    context "with pagination and Redis" do
      let!(:book1) { create(:book, created_at: 2.days.ago) }
      let!(:book2) { create(:book, created_at: 1.day.ago) }

      context "when Redis cache is available" do
        let(:cached_data) do
          {
            success: true,
            message: "Books retrieved successfully",
            books: [
              book2.as_json.merge(average_rating: 0, total_reviews: 0),
              book1.as_json.merge(average_rating: 0, total_reviews: 0)
            ],
            pagination: {
              current_page: 1,
              per_page: 10,
              total_pages: 1,
              total_count: 2
            }
          }.to_json
        end

        it "returns cached books when Redis has data" do
          expect(redis).to receive(:get).with("books:all:1:10:default").and_return(cached_data)
          result = BookService.index_books(1, 10)
          expect(result[:success]).to be_truthy
          expect(result[:message]).to eq("Books retrieved successfully")
          expect(result[:books].length).to eq(2)
          expect(result[:books].first[:id]).to eq(book2.id)
          expect(result[:pagination][:current_page]).to eq(1)
          expect(result[:pagination][:per_page]).to eq(10)
        end
      end

      context "when Redis cache is unavailable" do
        it "fetches from database and caches result" do
          expect(redis).to receive(:get).with("books:all:1:10:default").and_return(nil)
          expect(redis).to receive(:setex).with("books:all:1:10:default", 3600, anything)
          result = BookService.index_books(1, 10)
          expect(result[:success]).to be_truthy
          expect(result[:message]).to eq("Books retrieved successfully")
          expect(result[:books].length).to eq(2)
          expect(result[:books].first["id"]).to eq(book2.id)
          expect(result[:pagination][:current_page]).to eq(1)
          expect(result[:pagination][:per_page]).to eq(10)
          expect(result[:pagination][:total_pages]).to eq(1)
          expect(result[:pagination][:total_count]).to eq(2)
        end
      end

      context "with pagination" do
        before do
          15.times do |i|
            create(:book, created_at: (15 - i).days.ago)
          end
        end

        it "returns paginated books for page 1" do
          result = BookService.index_books(1, 10)
          expect(result[:success]).to be_truthy
          expect(result[:books].length).to eq(10)
          expect(result[:pagination][:current_page]).to eq(1)
          expect(result[:pagination][:total_pages]).to eq(2)
          expect(result[:pagination][:total_count]).to eq(17)
        end

        it "returns paginated books for page 2" do
          result = BookService.index_books(2, 10)
          expect(result[:success]).to be_truthy
          expect(result[:books].length).to eq(7)
          expect(result[:pagination][:current_page]).to eq(2)
          expect(result[:pagination][:total_pages]).to eq(2)
          expect(result[:pagination][:total_count]).to eq(17)
        end
      end

      context "when there are no active books" do
        it "returns an empty array with pagination" do
          Book.destroy_all
          result = BookService.index_books(1, 10)
          expect(result[:success]).to be_truthy
          expect(result[:message]).to eq("No books available")
          expect(result[:books]).to eq([])
          expect(result[:pagination][:current_page]).to eq(1)
          expect(result[:pagination][:per_page]).to eq(10)
          expect(result[:pagination][:total_pages]).to eq(0)
          expect(result[:pagination][:total_count]).to eq(0)
        end
      end

      context "when a database error occurs" do
        before do
          allow(Book).to receive(:active).and_raise(StandardError.new("Database connection failed"))
        end

        it "returns an error response" do
          result = BookService.index_books(1, 10)
          expect(result[:success]).to be_falsey
          expect(result[:error]).to eq("Internal server error occurred while retrieving books: Database connection failed")
        end
      end
    end
  end

  describe ".get_book_by_id" do
    let(:book) { create(:book) }

    context "when the book exists and is not deleted" do
      it "returns the book successfully from database" do
        expect(redis).to receive(:get).with("book:#{book.id}").and_return(nil)
        expect(redis).to receive(:setex).with("book:#{book.id}", 3600, anything)
        result = BookService.get_book_by_id(book.id)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book retrieved successfully")
        expect(result[:book]["id"]).to eq(book.id)
        expect(result[:book]["name"]).to eq(book.name)
        expect(result[:book]["author"]).to eq(book.author)
        expect(result[:book]["mrp"]).to eq(book.mrp.to_s)
        expect(result[:book]["discounted_price"]).to eq(book.discounted_price.to_s)
        expect(result[:book]["quantity"]).to eq(book.quantity)
        expect(result[:book]["book_details"]).to eq(book.book_details)
        expect(result[:book]["genre"]).to eq(book.genre)
        expect(result[:book]["book_image"]).to eq(book.book_image)
      end

      it "returns the book from Redis cache if available" do
        cached_data = {
          success: true,
          message: "Book retrieved successfully",
          book: book.as_json
        }.to_json
        expect(redis).to receive(:get).with("book:#{book.id}").and_return(cached_data)
        result = BookService.get_book_by_id(book.id)
        expect(result[:success]).to be_truthy
        expect(result[:book][:id]).to eq(book.id)
      end
    end

    context "when the book does not exist" do
      it "returns an error" do
        result = BookService.get_book_by_id(999)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found or has been deleted")
      end
    end

    context "when the book exists but is deleted" do
      let(:deleted_book) { create(:book, :deleted) }

      it "returns an error" do
        result = BookService.get_book_by_id(deleted_book.id)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found or has been deleted")
      end
    end
  end

  describe ".toggle_delete" do
    let(:book) { create(:book) }

    # Verify that create(:book) does not interact with Redis
    it "does not interact with Redis during book creation" do
      expect(redis).not_to receive(:get)
      expect(redis).not_to receive(:setex)
      expect(redis).not_to receive(:del)
      expect(redis).not_to receive(:keys)
      create(:book)
    end

    context "when the book exists and is not deleted" do
      it "marks the book as deleted and invalidates caches" do
        expect(redis).to receive(:keys).with("books:all:*").and_return(["books:all:1:10"])
        expect(redis).to receive(:del).with("books:all:1:10")
        expect(redis).to receive(:del).with("book:#{book.id}")
        result = BookService.toggle_delete(book.id)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book marked as deleted")
        expect(result[:book].is_deleted).to be_truthy
      end
    end

    context "when the book exists and is deleted" do
      let(:book) { create(:book, :deleted) }

      it "restores the book and invalidates caches" do
        expect(redis).to receive(:keys).with("books:all:*").and_return(["books:all:1:10"])
        expect(redis).to receive(:del).with("books:all:1:10")
        expect(redis).to receive(:del).with("book:#{book.id}")
        result = BookService.toggle_delete(book.id)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book restored")
        expect(result[:book].is_deleted).to be_falsey
      end
    end

    context "when the book does not exist" do
      it "returns an error" do
        result = BookService.toggle_delete(999)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found")
        expect(result[:book]).to be_nil
      end
    end
  end

  describe ".hard_delete" do
    let(:book) { create(:book) }

    context "when the book exists" do
      it "permanently deletes the book and invalidates caches" do
        expect(redis).to receive(:keys).with("books:all:*").and_return(["books:all:1:10"])
        expect(redis).to receive(:del).with("books:all:1:10")
        expect(redis).to receive(:del).with("book:#{book.id}")
        result = BookService.hard_delete(book.id)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book permanently deleted")
        expect(Book.exists?(book.id)).to be_falsey
      end
    end

    context "when the book does not exist" do
      it "returns an error" do
        result = BookService.hard_delete(999)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found")
      end
    end
  end

  describe ".search_suggestions" do
    let!(:book1) { create(:book, name: "The Great Gatsby", author: "F. Scott Fitzgerald", genre: "Fiction") }
    let!(:book2) { create(:book, name: "Gatsby's Adventure", author: "Jane Doe", genre: "Fiction") }
    let!(:book3) { create(:book, name: "1984", author: "George Orwell", genre: "Science Fiction") }

    context "with valid query" do
      it "returns a successful response for name search" do
        expect(redis).to receive(:get).with("books:search:gatsby").and_return(nil)
        expect(redis).to receive(:setex).with("books:search:gatsby", 1800, anything)
        result = BookService.search_suggestions("Gatsby")
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Search suggestions retrieved successfully")
        expect(result[:suggestions]).to be_an(Array)
        expect(result[:suggestions].length).to eq(2), "Expected 2 suggestions, got: #{result[:suggestions].length}"
      end

      it "returns a successful response for author search" do
        expect(redis).to receive(:get).with("books:search:fitzgerald").and_return(nil)
        expect(redis).to receive(:setex).with("books:search:fitzgerald", 1800, anything)
        result = BookService.search_suggestions("Fitzgerald")
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Search suggestions retrieved successfully")
        expect(result[:suggestions]).to be_an(Array)
        expect(result[:suggestions].length).to eq(1), "Expected 1 suggestion, got: #{result[:suggestions].length}"
      end

      it "returns a successful response for genre search" do
        expect(redis).to receive(:get).with("books:search:fiction").and_return(nil)
        expect(redis).to receive(:setex).with("books:search:fiction", 1800, anything)
        result = BookService.search_suggestions("Fiction")
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Search suggestions retrieved successfully")
        expect(result[:suggestions]).to be_an(Array)
        expect(result[:suggestions].length).to eq(3), "Expected 3 suggestions, got: #{result[:suggestions].length}"
      end

      it "returns cached suggestions when available" do
        cached_data = {
          success: true,
          message: "Search suggestions retrieved successfully",
          suggestions: [
            { name: "The Great Gatsby", author: "F. Scott Fitzgerald", genre: "Fiction" },
            { name: "Gatsby's Adventure", author: "Jane Doe", genre: "Fiction" }
          ]
        }.to_json
        expect(redis).to receive(:get).with("books:search:gatsby").and_return(cached_data)
        result = BookService.search_suggestions("Gatsby")
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Search suggestions retrieved successfully")
        expect(result[:suggestions].length).to eq(2)
      end
    end

    context "with invalid query" do
      it "returns an error for blank query" do
        result = BookService.search_suggestions("")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Query parameter is required")
      end

      it "returns an error for nil query" do
        result = BookService.search_suggestions(nil)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Query parameter is required")
      end
    end

    context "when database query fails" do
      before do
        allow(Book).to receive(:active).and_raise(StandardError.new("Database error"))
      end

      it "returns an error response" do
        result = BookService.search_suggestions("Gatsby")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Error retrieving suggestions: Database error")
      end
    end
  end

  describe ".fetch_stock" do
    let!(:book1) { create(:book, quantity: 10) }
    let!(:book2) { create(:book, quantity: 5) }

    context "with valid book_ids" do
      it "returns stock quantities for the given book IDs" do
        result = BookService.fetch_stock([book1.id, book2.id])
        expect(result[:success]).to be_truthy
        expect(result[:stock]).to eq([
          { book_id: book1.id, quantity: 10 },
          { book_id: book2.id, quantity: 5 }
        ])
      end
    end

    context "with some invalid book_ids" do
      it "returns an error for missing book IDs" do
        result = BookService.fetch_stock([book1.id, 999])
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Books not found: 999")
      end
    end

    context "with invalid input" do
      it "returns an error for non-array input" do
        result = BookService.fetch_stock(book1.id)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Invalid book_ids: must be an array of positive integers")
      end

      it "returns an error for array with non-positive integers" do
        result = BookService.fetch_stock([book1.id, -1])
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Invalid book_ids: must be an array of positive integers")
      end
    end

    context "when a database error occurs" do
      before do
        allow(Book).to receive(:where).and_raise(StandardError.new("Database error"))
      end

      it "returns an error response" do
        result = BookService.fetch_stock([book1.id])
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Failed to fetch stock quantities: Database error")
      end
    end
  end
end