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

  describe '.add_book' do
    context 'with valid attributes' do
      it 'adds a new book to the cart successfully' do
        new_book = Book.create!(name: 'New Book', author: 'Author', mrp: 500, discounted_price: 400, quantity: 5, is_deleted: false)
        cart_params = { user_id: user.id, book_id: new_book.id, quantity: 1 }
        result = CartService.add_book(cart_params)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book added to cart')
        expect(result[:cart].quantity).to eq(1)
      end

      it 'updates quantity if book is already in cart' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: 3 }
        result = CartService.add_book(cart_params)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book quantity updated in cart')
        expect(result[:cart].quantity).to eq(5) # 2 + 3
      end

      it 'handles large quantity additions' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: 100 }
        result = CartService.add_book(cart_params)

        expect(result[:success]).to be_truthy
        expect(result[:cart].quantity).to eq(102) # 2 + 100
      end

      it 'adds book with string quantity converted to integer' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: '5' }
        result = CartService.add_book(cart_params)

        expect(result[:success]).to be_truthy
        expect(result[:cart].quantity).to eq(7) # 2 + 5
      end
    end

    context 'with invalid attributes' do
      it 'returns an error for nil quantity' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: nil }
        result = CartService.add_book(cart_params)

        expect(result[:success]).to be_falsey # Fixed syntax error
        expect(result[:error]).to eq('Invalid quantity')
      end

      it 'returns an error for zero quantity' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: 0 }
        result = CartService.add_book(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Invalid quantity')
      end

      it 'returns an error for negative quantity' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: -1 }
        result = CartService.add_book(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Invalid quantity')
      end

      it 'returns an error for non-existent book' do
        cart_params = { user_id: user.id, book_id: 9999, quantity: 1 }
        result = CartService.add_book(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include('Book must exist')
      end

      it 'returns an error for non-existent user' do
        cart_params = { user_id: 9999, book_id: book.id, quantity: 1 }
        result = CartService.add_book(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to include('User must exist')
      end
    end
  end

  describe '.get_cart' do
    context 'with items in cart' do
      it 'retrieves cart successfully with one item' do
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart retrieved successfully')
        expect(result[:cart].size).to eq(1)
        expect(result[:cart].first[:book_name]).to eq(book.name)
      end

      it 'includes all fields for cart items' do
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:cart].first[:author_name]).to eq(book.author)
        expect(result[:cart].first[:price]).to eq(book.discounted_price)
        expect(result[:cart].first[:image_url]).to eq(book.book_image)
      end

      it 'retrieves multiple items correctly' do
        new_book = Book.create!(name: 'New Book', author: 'Author', mrp: 600, discounted_price: 500, quantity: 5, is_deleted: false)
        Cart.create!(user_id: user.id, book_id: new_book.id, quantity: 1, is_deleted: false)
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:cart].size).to eq(2)
      end

      it 'shows book details even if book is soft-deleted' do
        book.update(is_deleted: true)
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:cart].first[:book_name]).to eq('Ruby on Rails Guide')
      end

      it 'excludes soft-deleted cart items' do
        cart_item.update(is_deleted: true)
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart is empty')
        expect(result[:cart]).to eq([])
      end
    end

    context 'when cart is empty' do
      it 'returns empty cart when all items are soft-deleted' do
        Cart.where(user_id: user.id).update_all(is_deleted: true)
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart is empty')
        expect(result[:cart]).to eq([])
      end

      it 'returns empty cart for new user' do
        new_user = User.create!(name: 'Jane', email: 'jane@gmail.com', password: 'Password@123', mobile_number: '+919876543211')
        result = CartService.get_cart(new_user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart is empty')
        expect(result[:cart]).to eq([])
      end

      it 'handles nil user_id' do
        result = CartService.get_cart(nil)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart is empty')
        expect(result[:cart]).to eq([])
      end

      it 'handles non-existent user_id' do
        result = CartService.get_cart(9999)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Cart is empty')
        expect(result[:cart]).to eq([])
      end
    end

    context 'when an error occurs' do
      it 'handles database errors gracefully' do
        allow(Cart).to receive(:where).and_raise(StandardError.new('DB error'))
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Error retrieving cart: DB error')
      end
    end
  end

  describe '.soft_delete_book' do
    context 'with valid conditions' do
      it 'soft deletes cart item successfully' do
        result = CartService.soft_delete_book(book.id, user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book removed from cart')
        expect(result[:book].is_deleted).to be_truthy
      end

      it 'returns cart item details after deletion' do
        result = CartService.soft_delete_book(book.id, user.id)

        expect(result[:success]).to be_truthy
        expect(result[:book].book_id).to eq(book.id)
        expect(result[:book].user_id).to eq(user.id)
      end

      it 'works with multiple cart items present' do
        new_book = Book.create!(name: 'New Book', author: 'Author', mrp: 500, discounted_price: 400, quantity: 5, is_deleted: false)
        Cart.create!(user_id: user.id, book_id: new_book.id, quantity: 1, is_deleted: false)
        result = CartService.soft_delete_book(book.id, user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book removed from cart')
      end
    end

    context 'when item not found' do
      it 'returns error for non-existent book' do
        result = CartService.soft_delete_book(9999, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Cart item not found')
      end

      it 'returns error for non-existent user' do
        result = CartService.soft_delete_book(book.id, 9999)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Cart item not found')
      end

      it 'returns error for already deleted item' do
        cart_item.update(is_deleted: true)
        result = CartService.soft_delete_book(book.id, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Cart item not found')
      end
    end

    context 'when an error occurs' do
      it 'handles database errors gracefully' do
        allow(Cart).to receive(:find_by).and_raise(StandardError.new('DB error'))
        result = CartService.soft_delete_book(book.id, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Error updating cart item: DB error')
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