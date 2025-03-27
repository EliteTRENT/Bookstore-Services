require 'rails_helper'

RSpec.describe WishlistService, type: :service do
  let(:user) { User.create!(name: "John Doe", email: "john.doe@gmail.com", password: "Password@123", mobile_number: "9876543210") }
  let(:book) { Book.create!(name: "Sample Book", author: "Author", mrp: 20.0, discounted_price: 15.0, quantity: 5, is_deleted: false) }

  describe ".create" do
    context "with valid user and parameters" do
      let(:wishlist_params) { { book_id: book.id } }

      it "adds a book to the wishlist successfully" do
        result = WishlistService.create(user, wishlist_params)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book added to wishlist!")
        expect(user.wishlists.count).to eq(1)
        expect(user.wishlists.first.book_id).to eq(book.id)
        expect(user.wishlists.first.is_deleted).to be_falsey
      end
    end

    context "with nil user" do
      let(:wishlist_params) { { book_id: book.id } }

      it "returns an error due to invalid user" do
        result = WishlistService.create(nil, wishlist_params)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Invalid user")
      end
    end

    context "with non-existent user (simulated as nil)" do
      let(:wishlist_params) { { book_id: book.id } }

      it "returns an error" do
        result = WishlistService.create(nil, wishlist_params)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Invalid user")
      end
    end

    context "with non-existent book" do
      let(:wishlist_params) { { book_id: 999 } }

      it "returns an error" do
        result = WishlistService.create(user, wishlist_params)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Book not found")
      end
    end

    context "with soft-deleted book" do
      let(:deleted_book) { Book.create!(name: "Deleted Book", author: "Author", mrp: 20.0, discounted_price: 15.0, quantity: 5, is_deleted: true) }
      let(:wishlist_params) { { book_id: deleted_book.id } }

      it "creates wishlist but book association may be nil due to scope" do
        result = WishlistService.create(user, wishlist_params)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book added to wishlist!")
        expect(user.wishlists.first.book_id).to eq(deleted_book.id)
      end
    end

    context "with duplicate book in wishlist" do
      let(:wishlist_params) { { book_id: book.id } }

      before do
        WishlistService.create(user, wishlist_params)
      end

      it "returns an error" do
        result = WishlistService.create(user, wishlist_params)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Book is already in your wishlist")
      end
    end
  end

  describe ".index" do
    context "with valid user and existing wishlist" do
      before do
        user.wishlists.create!(book: book, is_deleted: false)
      end

      it "returns the user's wishlist successfully" do
        result = WishlistService.index(user)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to be_a(Array)
        expect(result[:message].length).to eq(1)
        expect(result[:message].first.book).to eq(book)
        expect(result[:message].first.is_deleted).to be_falsey
      end
    end

    context "with valid user and empty wishlist" do
      it "returns an empty wishlist successfully" do
        result = WishlistService.index(user)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq([])
      end
    end

    context "with valid user and soft-deleted book in wishlist" do
      let(:deleted_book) { Book.create!(name: "Deleted Book", author: "Author", mrp: 20.0, discounted_price: 15.0, quantity: 5, is_deleted: true) }
      let!(:wishlist_item) { user.wishlists.create!(book: deleted_book, is_deleted: false) }

      it "marks the wishlist item as deleted and returns an empty list" do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:info).with(/Marked wishlist item \d+ as deleted/)
        result = WishlistService.index(user)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq([])
        expect(wishlist_item.reload.is_deleted).to be_truthy
      end
    end

    context "with nil user" do
      it "returns an error due to invalid user" do
        result = WishlistService.index(nil)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Invalid user")
      end
    end

    context "with non-existent user (simulated as nil)" do
      it "returns an error" do
        result = WishlistService.index(nil)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Invalid user")
      end
    end
  end

  describe ".mark_book_as_deleted" do
    let!(:wishlist_item) { user.wishlists.create!(book: book, is_deleted: false) }

    context "with valid user and existing wishlist item" do
      it "marks the wishlist item as deleted successfully" do
        result = WishlistService.mark_book_as_deleted(user, wishlist_item.id)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Book removed from wishlist!")
        expect(wishlist_item.reload.is_deleted).to be_truthy
      end
    end

    context "with nil user" do
      it "returns an error due to invalid user" do
        result = WishlistService.mark_book_as_deleted(nil, wishlist_item.id)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Invalid user")
      end
    end

    context "with non-existent user (simulated as nil)" do
      it "returns an error" do
        result = WishlistService.mark_book_as_deleted(nil, wishlist_item.id)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Invalid user")
      end
    end

    context "with non-existent wishlist item" do
      it "returns an error" do
        result = WishlistService.mark_book_as_deleted(user, 999)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Wishlist item not found")
      end
    end

    context "with already deleted wishlist item" do
      before do
        wishlist_item.update!(is_deleted: true)
      end

      it "returns an error" do
        result = WishlistService.mark_book_as_deleted(user, wishlist_item.id)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Wishlist item not found")
      end
    end
  end
end