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

  describe '.add_book' do
    context 'with valid attributes' do
      it 'adds a book to the cart successfully' do
        result = CartService.add_book(user_id: user.id, book_id: book.id, quantity: 1)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book added to cart') # FIXED
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
        expect(result[:error]).to eq(['Book must exist']) # FIXED
      end
    end

    context 'when the user does not exist' do
      it 'returns an error' do
        result = CartService.add_book(user_id: 9999, book_id: book.id, quantity: 1)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq(['User must exist']) # FIXED
      end
    end

    context 'when the quantity is invalid' do
      it 'returns an error' do
        result = CartService.add_book(user_id: user.id, book_id: book.id, quantity: -1)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Invalid quantity') # Ensure your service handles this
      end
    end
  end
end
