require 'rails_helper'

RSpec.describe Api::V1::CartsController, type: :controller do
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

  describe 'POST #add_book' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          cart: {
            user_id: user.id,
            book_id: book.id,
            quantity: 2
          }
        }
      end

      it 'adds a new book to cart' do
        post :add_book, params: valid_params
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['message']).to eq('Book added to cart')
        expect(json_response['cart']['quantity']).to eq(2)
      end

      context 'when book already exists in cart' do
        let!(:existing_cart_item) do
          Cart.create!(
            user_id: user.id,
            book_id: book.id,
            quantity: 2,
            is_deleted: false
          )
        end

        it 'updates the quantity' do
          post :add_book, params: valid_params
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['message']).to eq('Book quantity updated in cart')
          expect(json_response['cart']['quantity']).to eq(4)
        end
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          cart: {
            user_id: user.id,
            book_id: book.id,
            quantity: 0
          }
        }
      end

      it 'returns an error' do
        post :add_book, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Invalid quantity')
      end
    end
  end

  describe 'GET #get_cart' do
    context 'when cart has items' do
      let!(:cart_item) do
        Cart.create!(
          user_id: user.id,
          book_id: book.id,
          quantity: 2,
          is_deleted: false
        )
      end

      it 'returns cart items' do
        get :get_cart, params: { user_id: user.id }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Cart retrieved successfully')
        expect(json_response['cart'].length).to eq(1)
        expect(json_response['cart'][0]['quantity']).to eq(2)
        expect(json_response['cart'][0]['book_name']).to eq(book.name)
      end
    end

    context 'when cart is empty' do
      it 'returns empty cart' do
        get :get_cart, params: { user_id: user.id }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Cart is empty')
        expect(json_response['cart']).to be_empty
      end
    end

    context 'when an error occurs' do
      it 'handles errors gracefully' do
        allow(Cart).to receive(:where).and_raise(StandardError.new('Database error'))
        get :get_cart, params: { user_id: user.id }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Error retrieving cart: Database error')
      end
    end
  end

  describe 'DELETE #soft_delete_book' do
    let(:token) { "mocked_token" }

    before do
      # Ensure the Authorization header is set before each test
      request.headers['Authorization'] = "Bearer #{token}"
    end

    context 'with valid token' do
      before do
        # Stub the token decoding and user lookup for valid token cases
        allow(JsonWebToken).to receive(:decode).with(token).and_return(user.email)
        allow(User).to receive(:find_by).with(email: user.email).and_return(user)
      end

      context 'when cart item exists' do
        let!(:cart_item) do
          Cart.create!(
            user_id: user.id,
            book_id: book.id,
            quantity: 2,
            is_deleted: false
          )
        end

        it 'decreases quantity if more than 1' do
          delete :soft_delete_book, params: { id: book.id }
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response['message']).to eq('Book quantity decreased in cart')
          expect(json_response['book']['quantity']).to eq(1)
        end

        context 'when quantity is 1' do
          let!(:cart_item) do
            Cart.create!(
              user_id: user.id,
              book_id: book.id,
              quantity: 1,
              is_deleted: false
            )
          end

          it 'soft deletes the cart item' do
            delete :soft_delete_book, params: { id: book.id }
            expect(response).to have_http_status(:ok)
            json_response = JSON.parse(response.body)
            expect(json_response['message']).to eq('Book removed from cart')
            expect(json_response['book']['is_deleted']).to be true
          end
        end
      end

      context 'when cart item does not exist' do
        it 'returns an error' do
          delete :soft_delete_book, params: { id: 9999 }
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Cart item not found')
        end
      end

      context 'when an error occurs' do
        it 'handles errors gracefully' do
          allow(Cart).to receive(:find_by).and_raise(StandardError.new('Database error'))
          delete :soft_delete_book, params: { id: book.id }
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response['error']).to eq('Error updating cart item: Database error')
        end
      end
    end

    context 'without token' do
      before do
        # Remove the Authorization header for this specific test
        request.headers['Authorization'] = nil
      end

      it 'fails due to nil user and raises NoMethodError' do
        expect {
          delete :soft_delete_book, params: { id: book.id }
        }.to raise_error(NoMethodError, /undefined method `id' for nil/)
      end
    end

    context 'with invalid token' do
      let(:invalid_token) { "invalid_token" }

      before do
        # Set an invalid token
        request.headers['Authorization'] = "Bearer #{invalid_token}"
        # Stub the token decoding to return nil for invalid token
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_return(nil)
      end

      it 'fails due to nil user and raises NoMethodError' do
        expect {
          delete :soft_delete_book, params: { id: book.id }
        }.to raise_error(NoMethodError, /undefined method `id' for nil/)
      end
    end
  end
end
