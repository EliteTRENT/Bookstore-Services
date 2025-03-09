require 'rails_helper'

RSpec.describe BookService, type: :service do
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
          result = BookService.update_book(book.id, update_attributes)
          expect(result[:success]).to be_truthy
          expect(result[:book].name).to eq("New Title")
          expect(result[:book].quantity).to eq(75)
          expect(result[:book].author).to eq("F. Scott Fitzgerald") # unchanged
          expect(result[:book].mrp).to eq(20.99) # unchanged
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
    context "when there are active books" do
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

      it "returns all active books in descending order" do
        result = BookService.get_all_books
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Books retrieved successfully")
        expect(result[:books].length).to eq(2)
        expect(result[:books].first.id).to eq(book2.id) # Newer book first
        expect(result[:books].last.id).to eq(book1.id)
      end
    end

    context "when there are no books" do
      it "returns an empty array with appropriate message" do
        result = BookService.get_all_books
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("No books available")
        expect(result[:books]).to eq([])
      end
    end

    context "when there are only deleted books" do
      let!(:deleted_book) do
        Book.create!(
          name: "Deleted Book",
          author: "Author",
          mrp: 20.99,
          discounted_price: 15.99,
          quantity: 100,
          is_deleted: true
        )
      end

      it "returns an empty array excluding deleted books" do
        result = BookService.get_all_books
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("No books available")
        expect(result[:books]).to eq([])
        expect(result[:books]).not_to include(deleted_book)
      end
    end

    context "when there are both active and deleted books" do
      let!(:active_book) do
        Book.create!(
          name: "Active Book",
          author: "Author 1",
          mrp: 20.99,
          discounted_price: 15.99,
          quantity: 100,
          is_deleted: false
        )
      end
      let!(:deleted_book) do
        Book.create!(
          name: "Deleted Book",
          author: "Author 2",
          mrp: 25.99,
          discounted_price: 19.99,
          quantity: 50,
          is_deleted: true
        )
      end

      it "returns only active books" do
        result = BookService.get_all_books
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Books retrieved successfully")
        expect(result[:books].length).to eq(1)
        expect(result[:books]).to include(active_book)
        expect(result[:books]).not_to include(deleted_book)
      end
    end

    context "when a database error occurs" do
      before do
        allow(Book).to receive(:where).and_raise(StandardError.new("Database connection failed"))
      end

      it "returns an error response" do
        result = BookService.get_all_books
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Internal server error occurred while retrieving books: Database connection failed")
        expect(result[:books]).to be_nil
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

      it "returns the book successfully" do
        result = BookService.get_book_by_id(book.id)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book retrieved successfully")
        expect(result[:book]).to eq(book)
        expect(result[:book].name).to eq("The Great Gatsby")
        expect(result[:book].author).to eq("F. Scott Fitzgerald")
        expect(result[:book].mrp).to eq(20.99)
        expect(result[:book].discounted_price).to eq(15.99)
        expect(result[:book].quantity).to eq(100)
        expect(result[:book].book_details).to eq("A story of the fabulously wealthy Jay Gatsby")
        expect(result[:book].genre).to eq("Fiction")
        expect(result[:book].book_image).to eq("http://example.com/book-cover.jpg")
      end
    end

    context "when the book does not exist" do
      it "returns an error" do
        result = BookService.get_book_by_id(999)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found or has been deleted")
        expect(result[:book]).to be_nil
      end
    end

    context "when the book exists but is deleted" do
      let!(:deleted_book) { Book.create!(valid_attributes.merge(is_deleted: true)) }

      it "returns an error" do
        result = BookService.get_book_by_id(deleted_book.id)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found or has been deleted")
        expect(result[:book]).to be_nil
      end
    end
  end
end
