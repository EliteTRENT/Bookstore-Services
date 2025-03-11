require 'rails_helper'

RSpec.describe OrderService, type: :service do
  let!(:user) do
    User.create!(
      name: "John Doe",
      email: "john@gmail.com",
      password: "Password123!",
      mobile_number: "+919876543210"
    )
  end

  let!(:book) do
    Book.create!(
      name: "Sample Book",
      author: "Author Name",
      mrp: 500.0,
      discounted_price: 400.0,
      quantity: 10,
      genre: "Fiction",
      book_details: "Some details",
      book_image: "image_url",
      is_deleted: false
    )
  end

  let!(:address) do
    Address.create!(
      user: user,
      street: "123 Street",
      city: "City",
      state: "State",
      zip_code: "12345",
      country: "Country",
      type: "home",
      is_default: true
    )
  end

  let(:valid_token) { "valid.jwt.token" }

  before do
    allow(JsonWebToken).to receive(:decode).with(valid_token).and_return(user.email)
  end

  describe ".create_order" do
    context "when the order is placed successfully" do
      let(:order_params) { { book_id: book.id, address_id: address.id, quantity: 2 } }

      it "returns a success response and updates book quantity" do
        response = OrderService.create_order(valid_token, order_params)

        expect(response[:success]).to be true
        expect(response[:message]).to eq("Order placed successfully")
        expect(response[:order]).to be_present
        expect(response[:order].user).to eq(user)
        expect(response[:order].book).to eq(book)
        expect(response[:order].address).to eq(address)
        expect(book.reload.quantity).to eq(8)
      end
    end

    context "when token is invalid" do
      it "returns an error response" do
        allow(JsonWebToken).to receive(:decode).with("invalid.token").and_return(nil)
        order_params = { book_id: book.id, address_id: address.id, quantity: 2 }
        response = OrderService.create_order("invalid.token", order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Invalid token")
      end
    end

    context "when user is not found" do
      it "returns an error response" do
        allow(JsonWebToken).to receive(:decode).with(valid_token).and_return("nonexistent@gmail.com")
        order_params = { book_id: book.id, address_id: address.id, quantity: 2 }
        response = OrderService.create_order(valid_token, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("User not found")
      end
    end

    context "when book is not found" do
      it "returns an error response" do
        order_params = { book_id: 9999, address_id: address.id, quantity: 2 }
        response = OrderService.create_order(valid_token, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Book not found")
      end
    end

    context "when address is invalid" do
      it "returns an error response" do
        order_params = { book_id: book.id, address_id: 9999, quantity: 2 }
        response = OrderService.create_order(valid_token, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Invalid address")
      end
    end

    context "when quantity is zero or negative" do
      it "returns an error response for zero quantity" do
        order_params = { book_id: book.id, address_id: address.id, quantity: 0 }
        response = OrderService.create_order(valid_token, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Invalid quantity")
      end

      it "returns an error response for negative quantity" do
        order_params = { book_id: book.id, address_id: address.id, quantity: -3 }
        response = OrderService.create_order(valid_token, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Invalid quantity")
      end
    end

    context "when quantity exceeds stock" do
      it "returns an error response" do
        order_params = { book_id: book.id, address_id: address.id, quantity: 15 }
        response = OrderService.create_order(valid_token, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Invalid quantity")
      end
    end

    context "when order creation fails due to validation" do
      it "returns an error response for invalid total_price" do
        order_params = { book_id: book.id, address_id: address.id, quantity: 2 }

        failed_order = Order.new(
          user: user,
          book: book,
          address: address,
          quantity: 2,
          price_at_purchase: book.discounted_price,
          status: "pending",
          total_price: 0
        )

        allow_any_instance_of(ActiveRecord::Associations::CollectionProxy).to receive(:create).with(
          book_id: book.id,
          address_id: address.id,
          quantity: 2,
          price_at_purchase: book.discounted_price,
          status: "pending",
          total_price: 2 * book.discounted_price
        ).and_return(failed_order)

        allow(failed_order).to receive(:persisted?).and_return(false)
        allow(failed_order).to receive(:errors).and_return(
          double(:errors, full_messages: [ "Total price must match quantity * price_at_purchase" ])
        )

        response = OrderService.create_order(valid_token, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to include("Total price must match quantity * price_at_purchase")
      end
    end
  end

  describe ".get_all_orders" do
    context "when user has orders" do
      let!(:order1) do
        user.orders.create!(
          book: book,
          address: address,
          quantity: 2,
          price_at_purchase: book.discounted_price,
          status: "pending",
          total_price: 2 * book.discounted_price
        )
      end

      let!(:order2) do
        user.orders.create!(
          book: book,
          address: address,
          quantity: 1,
          price_at_purchase: book.discounted_price,
          status: "shipped",
          total_price: book.discounted_price
        )
      end

      it "returns a success response with all user orders" do
        response = OrderService.get_all_orders(valid_token)

        expect(response[:success]).to be true
        expect(response[:orders]).to be_present
        expect(response[:orders].count).to eq(2)
        expect(response[:orders]).to include(order1, order2)
      end
    end

    context "when user has no orders" do
      it "returns an error response" do
        response = OrderService.get_all_orders(valid_token)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("No orders found")
      end
    end

    context "when token is invalid" do
      it "returns an error response" do
        allow(JsonWebToken).to receive(:decode).with("invalid.token").and_return(nil)
        response = OrderService.get_all_orders("invalid.token")

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Invalid token")
      end
    end

    context "when user is not found" do
      it "returns an error response" do
        allow(JsonWebToken).to receive(:decode).with(valid_token).and_return("nonexistent@gmail.com")
        response = OrderService.get_all_orders(valid_token)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("User not found")
      end
    end
  end
end
