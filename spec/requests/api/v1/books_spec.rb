require 'rails_helper'

RSpec.describe BookService, type: :service do
  # Setup Redis mock for testing
  let(:redis) { instance_double(Redis) }
  before do
    stub_const("BookService::REDIS", redis)
    allow(redis).to receive(:get).and_return(nil)
    allow(redis).to receive(:setex)
    allow(redis).to receive(:del)
    allow(redis).to receive(:keys).and_return([])
  end

  describe ".create_book" do
    context "with valid attributes" do
      let(:valid_attributes) do
        {
          name: "The Great Gatsby",
          author: "F. Scott Fitzgerald",
          mrp: 20.99,
          discounted_price: 15.99,
          quantity: 100,
          book_details: "A story of the fabulously wealthy Jay Gatsby",
          genre: "Fiction",
          book_image: "http://example.com/book-cover.jpg"
        }
      end

      it "creates a book successfully" do
        result = BookService.create_book(valid_attributes)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book created successfully")
        expect(result[:book]).to be_a(Book)
        expect(result[:book].persisted?).to be_truthy
        expect(result[:book].name).to eq("The Great Gatsby")
        expect(result[:book].author).to eq("F. Scott Fitzgerald")
        expect(result[:book].mrp).to eq(20.99)
        expect(result[:book].discounted_price).to eq(15.99)
        expect(result[:book].quantity).to eq(100)
      end

      it "creates a book successfully with only required fields" do
        minimal_attributes = {
          name: "The Great Gatsby",
          author: "F. Scott Fitzgerald",
          mrp: 20.99,
          discounted_price: 15.99,
          quantity: 100
        }
        result = BookService.create_book(minimal_attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].persisted?).to be_truthy
      end

      it "invalidates Redis cache for all books" do
        expect(redis).to receive(:keys).with("books:all:*").and_return([ "books:all:1:10" ])
        expect(redis).to receive(:del).with("books:all:1:10")
        BookService.create_book(valid_attributes)
      end
    end

    context "with invalid attributes" do
      let(:valid_attributes) do
        {
          name: "The Great Gatsby",
          author: "F. Scott Fitzgerald",
          mrp: 20.99,
          discounted_price: 15.99,
          quantity: 100
        }
      end

      it "returns an error when name is missing" do
        invalid_attributes = valid_attributes.merge(name: "")
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Name can't be blank")
      end

      it "returns an error when name is nil" do
        invalid_attributes = valid_attributes.merge(name: nil)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Name can't be blank")
      end

      it "returns an error when author is missing" do
        invalid_attributes = valid_attributes.merge(author: "")
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Author can't be blank")
      end

      it "returns an error when author is nil" do
        invalid_attributes = valid_attributes.merge(author: nil)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Author can't be blank")
      end

      it "returns an error when mrp is missing" do
        invalid_attributes = valid_attributes.merge(mrp: nil)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Mrp can't be blank")
      end

      it "returns an error when mrp is negative" do
        invalid_attributes = valid_attributes.merge(mrp: -5.0)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Mrp must be greater than or equal to 0")
      end

      it "returns an error when mrp is not a number" do
        invalid_attributes = valid_attributes.merge(mrp: "not_a_number")
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Mrp is not a number")
      end

      it "returns an error when discounted_price is missing" do
        invalid_attributes = valid_attributes.merge(discounted_price: nil)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Discounted price can't be blank")
      end

      it "returns an error when discounted_price is negative" do
        invalid_attributes = valid_attributes.merge(discounted_price: -5.0)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Discounted price must be greater than or equal to 0")
      end

      it "returns an error when discounted_price is not a number" do
        invalid_attributes = valid_attributes.merge(discounted_price: "not_a_number")
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Discounted price is not a number")
      end

      it "returns an error when quantity is missing" do
        invalid_attributes = valid_attributes.merge(quantity: nil)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Quantity can't be blank")
      end

      it "returns an error when quantity is negative" do
        invalid_attributes = valid_attributes.merge(quantity: -1)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Quantity must be greater than or equal to 0")
      end

      it "returns an error when quantity is not an integer" do
        invalid_attributes = valid_attributes.merge(quantity: 5.5)
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Quantity must be an integer")
      end

      it "returns an error when quantity is a string" do
        invalid_attributes = valid_attributes.merge(quantity: "not_a_number")
        result = BookService.create_book(invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Quantity is not a number")
      end

      it "accepts valid book_details when provided" do
        attributes = valid_attributes.merge(book_details: "A detailed description")
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].book_details).to eq("A detailed description")
      end

      it "accepts nil book_details" do
        attributes = valid_attributes.merge(book_details: nil)
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].book_details).to be_nil
      end

      it "accepts valid genre when provided" do
        attributes = valid_attributes.merge(genre: "Fiction")
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].genre).to eq("Fiction")
      end

      it "accepts nil genre" do
        attributes = valid_attributes.merge(genre: nil)
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].genre).to be_nil
      end

      it "accepts valid book_image when provided" do
        attributes = valid_attributes.merge(book_image: "http://example.com/image.jpg")
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].book_image).to eq("http://example.com/image.jpg")
      end

      it "accepts nil book_image" do
        attributes = valid_attributes.merge(book_image: nil)
        result = BookService.create_book(attributes)
        expect(result[:success]).to be_truthy
        expect(result[:book].book_image).to be_nil
      end

      it "returns multiple errors when multiple validations fail" do
        invalid_attributes = {
          name: "",
          author: "",
          mrp: -1,
          discounted_price: -1,
          quantity: -1
        }
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
    let(:valid_attributes) do
      {
        name: "The Great Gatsby",
        author: "F. Scott Fitzgerald",
        mrp: 20.99,
        discounted_price: 15.99,
        quantity: 100,
        book_details: "A story of the fabulously wealthy Jay Gatsby",
        genre: "Fiction",
        book_image: "http://example.com/book-cover.jpg"
      }
    end

    context "with existing book" do
      let!(:book) { Book.create!(valid_attributes.merge(is_deleted: false)) }

      context "with valid updates" do
        it "updates all attributes successfully" do
          update_attributes = {
            name: "Updated Title",
            author: "Updated Author",
            mrp: 25.99,
            discounted_price: 19.99,
            quantity: 50,
            book_details: "Updated details",
            genre: "Non-Fiction",
            book_image: "http://example.com/new-cover.jpg"
          }
          expect(redis).to receive(:keys).with("books:all:*").and_return([ "books:all:1:10" ])
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
          expect(redis).to receive(:keys).with("books:all:*").and_return([ "books:all:1:10" ])
          expect(redis).to receive(:del).with("books:all:1:10")
          expect(redis).to receive(:del).with("book:#{book.id}")
          result = BookService.update_book(book.id, update_attributes)
          expect(result[:success]).to be_truthy
          expect(result[:book].name).to eq("New Title")
          expect(result[:book].quantity).to eq(75)
          expect(result[:book].author).to eq("F. Scott Fitzgerald")
          expect(result[:book].mrp).to eq(20.99)
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
      let!(:deleted_book) { Book.create!(valid_attributes.merge(is_deleted: true)) }

      it "returns error when book is deleted" do
        result = BookService.update_book(deleted_book.id, { name: "New Title" })
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found or has been deleted")
      end
    end
  end

  describe ".get_all_books" do
    context "with pagination and Redis" do
      let!(:book1) do
        Book.create!(
          name: "Book 1",
          author: "Author 1",
          mrp: 20.99,
          discounted_price: 15.99,
          quantity: 100,
          is_deleted: false,
          created_at: 2.days.ago
        )
      end
      let!(:book2) do
        Book.create!(
          name: "Book 2",
          author: "Author 2",
          mrp: 25.99,
          discounted_price: 19.99,
          quantity: 50,
          is_deleted: false,
          created_at: 1.day.ago
        )
      end

      context "when Redis cache is available" do
        let(:cached_data) do
          {
            success: true,
            message: "Books retrieved successfully",
            books: [
              book2.as_json,
              book1.as_json
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
          expect(redis).to receive(:get).with("books:all:1:10").and_return(cached_data)
          result = BookService.get_all_books(1, 10)
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
          expect(redis).to receive(:get).with("books:all:1:10").and_return(nil)
          expect(redis).to receive(:setex).with("books:all:1:10", 3600, anything)
          result = BookService.get_all_books(1, 10)
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
            Book.create!(
              name: "Book #{i + 3}",
              author: "Author #{i + 3}",
              mrp: 10.0 + i,
              discounted_price: 8.0 + i,
              quantity: 10,
              is_deleted: false,
              created_at: (15 - i).days.ago
            )
          end
        end

        it "returns paginated books for page 1" do
          result = BookService.get_all_books(1, 10)
          expect(result[:success]).to be_truthy
          expect(result[:books].length).to eq(10)
          expect(result[:pagination][:current_page]).to eq(1)
          expect(result[:pagination][:total_pages]).to eq(2)
          expect(result[:pagination][:total_count]).to eq(17)
        end

        it "returns paginated books for page 2" do
          result = BookService.get_all_books(2, 10)
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
          result = BookService.get_all_books(1, 10)
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
          allow(Book).to receive(:where).and_raise(StandardError.new("Database connection failed"))
        end

        it "returns an error response" do
          result = BookService.get_all_books(1, 10)
          expect(result[:success]).to be_falsey
          expect(result[:error]).to eq("Internal server error occurred while retrieving books: Database connection failed")
        end
      end
    end
  end

  describe ".get_book_by_id" do
    let(:valid_attributes) do
      {
        name: "The Great Gatsby",
        author: "F. Scott Fitzgerald",
        mrp: 20.99,
        discounted_price: 15.99,
        quantity: 100,
        book_details: "A story of the fabulously wealthy Jay Gatsby",
        genre: "Fiction",
        book_image: "http://example.com/book-cover.jpg"
      }
    end

    context "when the book exists and is not deleted" do
      let!(:book) { Book.create!(valid_attributes.merge(is_deleted: false)) }

      it "returns the book successfully from database" do
        expect(redis).to receive(:get).with("book:#{book.id}").and_return(nil)
        expect(redis).to receive(:setex).with("book:#{book.id}", 3600, anything)
        result = BookService.get_book_by_id(book.id)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book retrieved successfully")
        expect(result[:book]["id"]).to eq(book.id)
        expect(result[:book]["name"]).to eq("The Great Gatsby")
        expect(result[:book]["author"]).to eq("F. Scott Fitzgerald")
        expect(result[:book]["mrp"]).to eq("20.99")
        expect(result[:book]["discounted_price"]).to eq("15.99")
        expect(result[:book]["quantity"]).to eq(100)
        expect(result[:book]["book_details"]).to eq("A story of the fabulously wealthy Jay Gatsby")
        expect(result[:book]["genre"]).to eq("Fiction")
        expect(result[:book]["book_image"]).to eq("http://example.com/book-cover.jpg")
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
      let!(:deleted_book) { Book.create!(valid_attributes.merge(is_deleted: true)) }

      it "returns an error" do
        result = BookService.get_book_by_id(deleted_book.id)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found or has been deleted")
      end
    end
  end

  describe ".toggle_delete" do
    let(:valid_attributes) do
      {
        name: "The Great Gatsby",
        author: "F. Scott Fitzgerald",
        mrp: 20.99,
        discounted_price: 15.99,
        quantity: 100
      }
    end

    context "when the book exists and is not deleted" do
      let!(:book) { Book.create!(valid_attributes.merge(is_deleted: false)) }

      it "marks the book as deleted and invalidates caches" do
        expect(redis).to receive(:keys).with("books:all:*").and_return([ "books:all:1:10" ])
        expect(redis).to receive(:del).with("books:all:1:10")
        expect(redis).to receive(:del).with("book:#{book.id}")
        result = BookService.toggle_delete(book.id)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book marked as deleted")
        expect(result[:book].is_deleted).to be_truthy
      end
    end

    context "when the book exists and is deleted" do
      let!(:book) { Book.create!(valid_attributes.merge(is_deleted: true)) }

      it "restores the book and invalidates caches" do
        expect(redis).to receive(:keys).with("books:all:*").and_return([ "books:all:1:10" ])
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

    context "when the update fails due to validation" do
      let!(:book) { Book.create!(valid_attributes.merge(is_deleted: false)) }

      before do
        allow_any_instance_of(Book).to receive(:update).and_return(false)
        allow_any_instance_of(Book).to receive(:errors).and_return(double(full_messages: [ "Validation failed" ]))
      end

      it "returns an error" do
        result = BookService.toggle_delete(book.id)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq([ "Validation failed" ])
      end
    end
  end

  describe ".hard_delete" do
    let(:valid_attributes) do
      { name: "The Great Gatsby", author: "F. Scott Fitzgerald", mrp: 20.99, discounted_price: 15.99, quantity: 100 }
    end

    context "when the book exists" do
      let!(:book) { Book.create!(valid_attributes.merge(is_deleted: false)) }

      it "permanently deletes the book and invalidates caches" do
        expect(redis).to receive(:keys).with("books:all:*").and_return([ "books:all:1:10" ])
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
    let!(:book1) do
      Book.create!(
        name: "The Great Gatsby",
        author: "F. Scott Fitzgerald",
        mrp: 20.99,
        discounted_price: 15.99,
        quantity: 100,
        genre: "Fiction",
        is_deleted: false
      )
    end
    let!(:book2) do
      Book.create!(
        name: "Gatsby's Adventure",
        author: "Jane Doe",
        mrp: 15.99,
        discounted_price: 12.99,
        quantity: 50,
        genre: "Fiction",
        is_deleted: false
      )
    end
    let!(:book3) do
      Book.create!(
        name: "1984",
        author: "George Orwell",
        mrp: 10.99,
        discounted_price: 8.99,
        quantity: 75,
        genre: "Science Fiction",
        is_deleted: false
      )
    end

    context "with valid query" do
      it "returns suggestions matching name from database" do
        expect(redis).to receive(:get).with("books:search:gatsby").and_return(nil)
        expect(redis).to receive(:setex).with("books:search:gatsby", 1800, anything)
        result = BookService.search_suggestions("Gatsby")
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Search suggestions retrieved successfully")
        expect(result[:suggestions].length).to eq(2)
        expect(result[:suggestions]).to include(
          { name: "The Great Gatsby", author: "F. Scott Fitzgerald", genre: "Fiction" },
          { name: "Gatsby's Adventure", author: "Jane Doe", genre: "Fiction" }
        )
      end

      it "returns suggestions from Redis cache if available" do
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
        expect(result[:suggestions].length).to eq(2)
        expect(result[:suggestions]).to eq(
          [
            { name: "The Great Gatsby", author: "F. Scott Fitzgerald", genre: "Fiction" },
            { name: "Gatsby's Adventure", author: "Jane Doe", genre: "Fiction" }
          ]
        )
      end

      it "returns suggestions matching author" do
        expect(redis).to receive(:get).with("books:search:fitzgerald").and_return(nil)
        expect(redis).to receive(:setex).with("books:search:fitzgerald", 1800, anything)
        result = BookService.search_suggestions("Fitzgerald")
        expect(result[:success]).to be_truthy
        expect(result[:suggestions].length).to eq(1)
        expect(result[:suggestions].first[:name]).to eq("The Great Gatsby")
      end

      it "returns all suggestions matching genre substring" do
        expect(redis).to receive(:get).with("books:search:fiction").and_return(nil)
        expect(redis).to receive(:setex).with("books:search:fiction", 1800, anything)
        result = BookService.search_suggestions("Fiction")
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Search suggestions retrieved successfully")
        expect(result[:suggestions].length).to eq(3)  # Matches original fuzzy search behavior
        expect(result[:suggestions]).to include(
          { name: "The Great Gatsby", author: "F. Scott Fitzgerald", genre: "Fiction" },
          { name: "Gatsby's Adventure", author: "Jane Doe", genre: "Fiction" },
          { name: "1984", author: "George Orwell", genre: "Science Fiction" }
        )
      end
    end

    context "with no matches" do
      it "returns an empty array" do
        expect(redis).to receive(:get).with("books:search:nonexistent").and_return(nil)
        expect(redis).to receive(:setex).with("books:search:nonexistent", 1800, anything)
        result = BookService.search_suggestions("Nonexistent")
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Search suggestions retrieved successfully")
        expect(result[:suggestions]).to eq([])
      end
    end

    context "with invalid query" do
      it "returns an error when query is blank" do
        result = BookService.search_suggestions("")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Query parameter is required")
      end

      it "returns an error when query is nil" do
        result = BookService.search_suggestions(nil)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Query parameter is required")
      end
    end

    context "when a database error occurs" do
      before do
        allow(Book).to receive(:where).and_raise(StandardError.new("Search error"))
      end

      it "returns an error response" do
        result = BookService.search_suggestions("Gatsby")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Error retrieving suggestions: Search error")
      end
    end
  end
end
