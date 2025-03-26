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
      book_image: 'image_url',
      is_deleted: false
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

  describe '.create' do
    context 'with valid attributes' do
      it 'adds a new book to the cart successfully' do
        new_book = Book.create!(name: 'Test Book', author: 'Test', mrp: 500, discounted_price: 400, quantity: 5, is_deleted: false)
        cart_params = { user_id: user.id, book_id: new_book.id, quantity: 1 }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book added to cart')
        expect(result[:cart].quantity).to eq(1)
      end

      it 'updates quantity if book is already in cart' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: 3 }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book quantity updated in cart')
        expect(result[:cart].quantity).to eq(5)
      end

      it 'handles large quantity updates correctly' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: 100 }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_truthy
        expect(result[:cart].quantity).to eq(102) # 2 + 100
      end

      it 'adds book with minimum valid quantity' do
        new_book = Book.create!(name: 'Min Book', author: 'Min', mrp: 300, discounted_price: 200, quantity: 5, is_deleted: false)
        cart_params = { user_id: user.id, book_id: new_book.id, quantity: 1 }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book added to cart')
      end
    end

    context 'when quantity is invalid' do
      it 'returns an error for nil quantity' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: nil }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Invalid quantity')
      end

      it 'returns an error for zero quantity' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: 0 }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Invalid quantity')
      end

      it 'returns an error for negative quantity' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: -1 }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Invalid quantity')
      end

      it 'returns an error for string quantity' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: 'invalid' }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Invalid quantity') # 'invalid'.to_i = 0
      end
    end

    context 'when save fails due to validation' do
      it 'returns an error for non-existent book' do
        cart_params = { user_id: user.id, book_id: 9999, quantity: 1 }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include('Book must exist')
      end

      it 'returns an error for non-existent user' do
        cart_params = { user_id: 9999, book_id: book.id, quantity: 1 }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include('User must exist')
      end

      it 'returns an error when cart save fails unexpectedly' do
        allow_any_instance_of(Cart).to receive(:save).and_return(false)
        allow_any_instance_of(Cart).to receive(:errors).and_return(double(full_messages: [ 'Save failed' ]))
        cart_params = { user_id: user.id, book_id: book.id, quantity: 1 }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq([ 'Save failed' ])
      end
    end
  end

  describe '.get_cart' do
    context 'when the cart has items' do
      it 'retrieves the cart successfully with one item' do
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart retrieved successfully')
        expect(result[:cart].size).to eq(1)
        expect(result[:cart].first[:book_name]).to eq(book.name)
      end

      it 'retrieves the cart with multiple items' do
        new_book = Book.create!(name: 'New Book', author: 'Author', mrp: 600, discounted_price: 500, quantity: 5, is_deleted: false)
        Cart.create!(user_id: user.id, book_id: new_book.id, quantity: 1, is_deleted: false)
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:cart].size).to eq(2)
      end

      it 'includes correct pricing for items' do
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:cart].first[:price]).to eq(book.discounted_price)
      end

      it 'handles soft-deleted books by still showing their names' do
        book.update(is_deleted: true)
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:cart].first[:book_name]).to eq('Ruby on Rails Guide') # Fixed failing test
      end

      it 'excludes soft-deleted cart items' do
        cart_item.update(is_deleted: true)
        new_book = Book.create!(name: 'Active Book', author: 'Author', mrp: 700, discounted_price: 600, quantity: 5, is_deleted: false)
        Cart.create!(user_id: user.id, book_id: new_book.id, quantity: 1, is_deleted: false)
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:cart].size).to eq(1)
        expect(result[:cart].first[:book_name]).to eq('Active Book')
      end
    end

    context 'when the cart is empty' do
      it 'returns an empty cart when no items exist' do
        Cart.where(user_id: user.id).update_all(is_deleted: true)
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart is empty')
        expect(result[:cart]).to eq([])
      end

      it 'returns an empty cart for a user with no cart history' do
        new_user = User.create!(
          name: 'Jane',
          email: 'jane@gmail.com',
          password: 'Password@123',
          mobile_number: '+919876543211'
        )
        result = CartService.get_cart(new_user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart is empty')
        expect(result[:cart]).to eq([])
      end

      it 'handles invalid user_id gracefully' do
        result = CartService.get_cart(9999)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart is empty')
        expect(result[:cart]).to eq([])
      end
    end

    context 'when an error occurs' do
      it 'handles database connection errors gracefully' do
        allow(Cart).to receive(:where).and_raise(StandardError.new('Database error'))
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Error retrieving cart: Database error')
      end

      it 'handles nil user_id gracefully' do
        result = CartService.get_cart(nil)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart is empty')
        expect(result[:cart]).to eq([])
      end
    end
  end

  describe '.soft_delete_book' do
    context 'when book exists and is not soft deleted' do
      it 'soft deletes the book successfully' do
        result = CartService.soft_delete_book(book.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book soft deleted successfully')
        expect(result[:book].is_deleted).to be_truthy
      end

      it 'returns the updated book object' do
        result = CartService.soft_delete_book(book.id)

        expect(result[:success]).to be_truthy
        expect(result[:book].id).to eq(book.id)
      end
    end

    context 'when book does not exist or is already soft deleted' do
      it 'returns an error for non-existent book' do
        result = CartService.soft_delete_book(9999)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Book not found')
      end

      it 'returns an error for already soft-deleted book' do
        book.update(is_deleted: true)
        result = CartService.soft_delete_book(book.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Book not found')
      end

      it 'handles nil book_id gracefully' do
        result = CartService.soft_delete_book(nil)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Book not found')
      end
    end

    context 'when an error occurs' do
      it 'handles database errors gracefully' do
        allow(Book).to receive(:active).and_raise(StandardError.new('Database error'))
        result = CartService.soft_delete_book(book.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Error soft deleting book: Database error')
      end

      it 'returns an error if update fails' do
        allow_any_instance_of(Book).to receive(:update).and_return(false)
        allow_any_instance_of(Book).to receive(:errors).and_return(double(full_messages: [ 'Update failed' ]))

        result = CartService.soft_delete_book(book.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq([ 'Update failed' ])
      end
    end
  end

  describe '.update_quantity' do
    context 'with valid attributes' do
      it 'updates quantity successfully' do
        cart_params = { book_id: book.id, quantity: 5 }
        result = CartService.update_quantity(cart_params, user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart quantity updated')
        expect(result[:cart].quantity).to eq(5)
      end

      it 'sets quantity to minimum valid value' do
        cart_params = { book_id: book.id, quantity: 1 }
        result = CartService.update_quantity(cart_params, user.id)

        expect(result[:success]).to be_truthy
        expect(result[:cart].quantity).to eq(1)
      end

      it 'updates quantity with string input' do
        cart_params = { book_id: book.id, quantity: '3' }
        result = CartService.update_quantity(cart_params, user.id)

        expect(result[:success]).to be_truthy
        expect(result[:cart].quantity).to eq(3)
      end
    end

    context 'with invalid attributes' do
      it 'returns error for nil quantity' do
        cart_params = { book_id: book.id, quantity: nil }
        result = CartService.update_quantity(cart_params, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Invalid quantity')
      end

      it 'returns error for zero quantity' do
        cart_params = { book_id: book.id, quantity: 0 }
        result = CartService.update_quantity(cart_params, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Invalid quantity')
      end

      it 'returns error for non-existent cart item' do
        cart_params = { book_id: 9999, quantity: 1 }
        result = CartService.update_quantity(cart_params, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Cart item not found')
      end

      it 'handles database errors' do
        cart_params = { book_id: book.id, quantity: 5 }
        allow(Cart).to receive(:find_by).and_raise(StandardError.new('DB error'))
        result = CartService.update_quantity(cart_params, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Error updating cart quantity: DB error')
      end
    end
  end
end
