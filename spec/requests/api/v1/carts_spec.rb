require 'rails_helper'

RSpec.describe CartService, type: :service do
  let!(:user) do
    User.create!(
      name: 'John Doe',
      email: 'john.doe@gmail.com',
      password: 'Password@123',
      mobile_number: '+919876543210'
    )
  end

  let!(:book) do
    Book.create!(
      name: 'Ruby on Rails Guide',
      author: 'David Heinemeier Hansson',
      mrp: 1000.0,
      discounted_price: 800.0,
      quantity: 10,
      book_details: 'A complete guide to Rails',
      genre: 'Technology',
      book_image: 'image_url'
    )
  end

  let!(:cart_item) do
    Cart.create!(
      user_id: user.id,
      book_id: book.id,
      quantity: 2,
      is_deleted: false
    )
  end

  describe '.add_book' do
    context 'with valid attributes' do
      it 'adds a book to the cart successfully' do
        result = CartService.add_book(user_id: user.id, book_id: book.id, quantity: 1)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book added to cart')
        expect(result[:cart]).to be_present
        expect(result[:cart].user_id).to eq(user.id)
        expect(result[:cart].book_id).to eq(book.id)
        expect(result[:cart].quantity).to eq(1)
      end
    end

    context 'when the book does not exist' do
      it 'returns an error' do
        result = CartService.add_book(user_id: user.id, book_id: 9999, quantity: 1)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq(['Book must exist'])
      end
    end

    context 'when the user does not exist' do
      it 'returns an error' do
        result = CartService.add_book(user_id: 9999, book_id: book.id, quantity: 1)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq(['User must exist'])
      end
    end

    context 'when the quantity is invalid' do
      it 'returns an error' do
        result = CartService.add_book(user_id: user.id, book_id: book.id, quantity: -1)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Invalid quantity')
      end
    end
  end

  describe '.get_cart' do
    context 'when the cart has items' do
      it 'retrieves the cart successfully' do
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart retrieved successfully')
        expect(result[:cart]).to be_an(Array)
        expect(result[:cart].first[:cart_id]).to eq(cart_item.id)
        expect(result[:cart].first[:book_id]).to eq(book.id)
        expect(result[:cart].first[:book_name]).to eq(book.name)
        expect(result[:cart].first[:quantity]).to eq(cart_item.quantity)
      end
    end

    context 'when the cart is empty' do
      it 'returns an empty cart' do
        Cart.where(user_id: user.id).delete_all # Empty the cart

        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart is empty')
        expect(result[:cart]).to eq([])
      end
    end

    context 'when an error occurs' do
      it 'handles errors gracefully' do
        allow(Cart).to receive(:where).and_raise(StandardError.new('Database error'))

        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Error retrieving cart: Database error')
      end
    end
  end

  # New tests for soft delete functionality
  describe '.soft_delete_book' do
    context 'when book exists and is not soft deleted' do
      it 'soft deletes the book successfully' do
        result = CartService.soft_delete_book(book.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book soft deleted successfully')
        expect(result[:book]).to be_present
        expect(result[:book].deleted_at).not_to be_nil
      end
    end

    context 'when book does not exist' do
      it 'returns an error' do
        result = CartService.soft_delete_book(9999)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Book not found')
      end
    end

    context 'when book is already soft deleted' do
      let!(:deleted_book) do
        Book.create!(
          name: 'Deleted Book',
          author: 'Test Author',
          mrp: 1000.0,
          discounted_price: 800.0,
          quantity: 10,
          book_details: 'Test details',
          genre: 'Test genre',
          book_image: 'test_url',
          deleted_at: Time.current
        )
      end

      it 'returns book not found' do
        result = CartService.soft_delete_book(deleted_book.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Book not found')
      end
    end

    context 'when an error occurs' do
      it 'handles errors gracefully' do
        allow(Book).to receive(:active).and_raise(StandardError.new('Database error'))
        
        result = CartService.soft_delete_book(book.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Error soft deleting book: Database error')
      end
    end
  end
end