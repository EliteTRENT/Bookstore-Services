require 'rails_helper'

RSpec.describe CartService, type: :service do
  let!(:user) { create(:user) }
  let!(:book) { create(:book) }
  let!(:cart_item) { create(:cart, user: user, book: book, quantity: 2) }

  describe '.create' do
    context 'with valid attributes' do
      it 'adds a new book to the cart successfully' do
        new_book = create(:book)
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
        expect(result[:cart].quantity).to eq(5) # 2 + 3
      end

      it 'handles large quantity updates correctly' do
        cart_params = { user_id: user.id, book_id: book.id, quantity: 100 }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book quantity updated in cart')
        expect(result[:cart].quantity).to eq(102) # 2 + 100
      end

      it 'adds book with minimum valid quantity' do
        new_book = create(:book)
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
        expect(result[:error]).to eq('Invalid quantity')
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
        allow_any_instance_of(Cart).to receive(:errors).and_return(double(full_messages: ['Save failed']))
        cart_params = { user_id: user.id, book_id: book.id, quantity: 1 }
        result = CartService.create(cart_params)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq(['Save failed'])
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
        new_book = create(:book)
        create(:cart, user: user, book: new_book, quantity: 1)
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
        expect(result[:cart].first[:book_name]).to eq(book.name)
      end

      it 'excludes soft-deleted cart items' do
        cart_item.update(is_deleted: true)
        new_book = create(:book)
        create(:cart, user: user, book: new_book, quantity: 1)
        result = CartService.get_cart(user.id)

        expect(result[:success]).to be_truthy
        expect(result[:cart].size).to eq(1)
        expect(result[:cart].first[:book_name]).to eq(new_book.name)
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
        new_user = create(:user)
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
    context 'when cart item exists and is not soft deleted' do
      it 'soft deletes the cart item successfully' do
        result = CartService.soft_delete_book(book.id, user.id)

        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq('Book removed from cart')
        expect(result[:book].is_deleted).to be_truthy
      end

      it 'returns the updated cart item object' do
        result = CartService.soft_delete_book(book.id, user.id)

        expect(result[:success]).to be_truthy
        expect(result[:book].id).to eq(cart_item.id)
      end
    end

    context 'when cart item does not exist or is already soft deleted' do
      it 'returns an error for non-existent cart item' do
        result = CartService.soft_delete_book(9999, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Cart item not found')
      end

      it 'returns an error for already soft-deleted cart item' do
        cart_item.update(is_deleted: true)
        result = CartService.soft_delete_book(book.id, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Cart item not found')
      end

      it 'handles nil book_id gracefully' do
        result = CartService.soft_delete_book(nil, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Cart item not found')
      end
    end

    context 'when an error occurs' do
      it 'handles database errors gracefully' do
        allow(Cart).to receive(:find_by).and_raise(StandardError.new('Database error'))
        result = CartService.soft_delete_book(book.id, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq('Error updating cart item: Database error')
      end

      it 'returns an error if update fails' do
        cart_item # Ensure cart_item is created before mocking
        allow_any_instance_of(Cart).to receive(:update).and_return(false)
        allow_any_instance_of(Cart).to receive(:errors).and_return(double(full_messages: ['Update failed']))
        result = CartService.soft_delete_book(book.id, user.id)

        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq(['Update failed'])
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