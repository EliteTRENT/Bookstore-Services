require 'rails_helper'

RSpec.describe WishlistService, type: :service do
  let(:user) { User.create!(name: "John Doe", email: "john.doe@gmail.com", password: "Password@123", mobile_number: "9876543210") }
  let(:book) { Book.create!(name: "Sample Book", author: "Author", mrp: 20.0, discounted_price: 15.0, quantity: 5, is_deleted: false) }
  let(:valid_token) { JsonWebToken.encode({ email: user.email, id: user.id }) }
  let(:invalid_token) { "invalid.token.here" }

  describe ".create" do
    context "with valid token and parameters" do
      let(:wishlist_params) { { book_id: book.id } }

      it "adds a book to the wishlist successfully" do
        result = WishlistService.create(valid_token, wishlist_params)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book added to wishlist!")
        expect(user.wishlists.count).to eq(1)
        expect(user.wishlists.first.book_id).to eq(book.id)
        expect(user.wishlists.first.is_deleted).to be_falsey
      end
    end

    context "with invalid token" do
      let(:wishlist_params) { { book_id: book.id } }

      it "raises an error due to unhandled nil token" do
        # Mock decode to return nil
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_return(nil)
        expect { WishlistService.create(invalid_token, wishlist_params) }.to raise_error(NoMethodError)
        # Note: Ideally, this should return { success: false, error: "Invalid token" }
        # but the current service code crashes instead
      end
    end

    context "with non-existent user" do
      let(:wishlist_params) { { book_id: book.id } }
      let(:token_with_invalid_email) { JsonWebToken.encode({ email: "unknown@gmail.com", id: 999 }) }

      it "returns an error" do
        result = WishlistService.create(token_with_invalid_email, wishlist_params)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("User not found")
      end
    end

    context "with non-existent book" do
      let(:wishlist_params) { { book_id: 999 } }

      it "returns an error" do
        result = WishlistService.create(valid_token, wishlist_params)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found")
      end
    end

    context "with soft-deleted book" do
      let(:deleted_book) { Book.create!(name: "Deleted Book", author: "Author", mrp: 20.0, discounted_price: 15.0, quantity: 5, is_deleted: true) }
      let(:wishlist_params) { { book_id: deleted_book.id } }

      it "creates wishlist but book association is nil due to scope" do
        result = WishlistService.create(valid_token, wishlist_params)
        expect(result[:success]).to be_truthy # Current behavior
        expect(result[:message]).to eq("Book added to wishlist!")
        expect(user.wishlists.first.book_id).to eq(deleted_book.id)
        expect(user.wishlists.first.book).to be_nil # Due to belongs_to scope
        # Note: This might be unintended; ideally, it should fail with "Book not found"
      end
    end

    context "with duplicate book in wishlist" do
      let(:wishlist_params) { { book_id: book.id } }

      before do
        WishlistService.create(valid_token, wishlist_params)
      end

      it "returns an error" do
        result = WishlistService.create(valid_token, wishlist_params)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Book is already in your wishlist")
      end
    end
  end

  describe ".index" do
    context "with valid token and existing wishlist" do
      before do
        user.wishlists.create!(book: book, is_deleted: false)
      end

      it "returns the user's wishlist successfully" do
        result = WishlistService.index(valid_token)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to be_a(Array)
        expect(result[:message].length).to eq(1)
        expect(result[:message].first.book).to eq(book)
        expect(result[:message].first.is_deleted).to be_falsey
      end
    end

    context "with valid token and empty wishlist" do
      it "returns an empty wishlist successfully" do
        result = WishlistService.index(valid_token)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq([])
      end
    end

    context "with valid token and soft-deleted book in wishlist" do
      let(:deleted_book) { Book.create!(name: "Deleted Book", author: "Author", mrp: 20.0, discounted_price: 15.0, quantity: 5, is_deleted: true) }
      let!(:wishlist_item) { user.wishlists.create!(book: deleted_book, is_deleted: false) }

      it "marks the wishlist item as deleted and returns an empty list" do
        allow(Rails.logger).to receive(:info) # Allow JWT logging
        expect(Rails.logger).to receive(:info).with(/Marked wishlist item \d+ as deleted/)
        result = WishlistService.index(valid_token)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq([])
        expect(wishlist_item.reload.is_deleted).to be_truthy
      end
    end

    context "with invalid token" do
      it "raises an error due to unhandled nil token" do
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_return(nil)
        expect { WishlistService.index(invalid_token) }.to raise_error(NoMethodError)
        # Note: Should return { success: false, error: "Invalid token" } but crashes
      end
    end

    context "with non-existent user" do
      let(:token_with_invalid_email) { JsonWebToken.encode({ email: "unknown@gmail.com", id: 999 }) }

      it "returns an error" do
        result = WishlistService.index(token_with_invalid_email)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("User not found")
      end
    end
  end

  describe ".mark_book_as_deleted" do
    let!(:wishlist_item) { user.wishlists.create!(book: book, is_deleted: false) }

    context "with valid token and existing wishlist item" do
      it "marks the wishlist item as deleted successfully" do
        result = WishlistService.mark_book_as_deleted(valid_token, wishlist_item.id)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book removed from wishlist!")
        expect(wishlist_item.reload.is_deleted).to be_truthy
      end
    end

    context "with invalid token" do
      it "raises an error due to unhandled nil token" do
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_return(nil)
        expect { WishlistService.mark_book_as_deleted(invalid_token, wishlist_item.id) }.to raise_error(NoMethodError)
        # Note: Should return { success: false, error: "Invalid token" } but crashes
      end
    end

    context "with non-existent user" do
      let(:token_with_invalid_email) { JsonWebToken.encode({ email: "unknown@gmail.com", id: 999 }) }

      it "returns an error" do
        result = WishlistService.mark_book_as_deleted(token_with_invalid_email, wishlist_item.id)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("User not found")
      end
    end

    context "with non-existent wishlist item" do
      it "returns an error" do
        result = WishlistService.mark_book_as_deleted(valid_token, 999)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Wishlist item not found")
      end
    end

    context "with already deleted wishlist item" do
      before do
        wishlist_item.update!(is_deleted: true)
      end

      it "returns an error" do
        result = WishlistService.mark_book_as_deleted(valid_token, wishlist_item.id)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Wishlist item not found")
      end
    end
  end
end