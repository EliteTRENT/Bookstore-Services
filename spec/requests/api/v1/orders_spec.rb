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

  describe ".create_order" do
    context "when the order is placed successfully" do
      let(:order_params) do
        {
          book_id: book.id,
          address_id: address.id,
          quantity: 2,
          price_at_purchase: book.discounted_price,
          total_price: 2 * book.discounted_price
        }
      end

      it "returns a success response and updates book quantity" do
        response = OrderService.create_order(user.id, order_params)

        expect(response[:success]).to be true
        expect(response[:message]).to eq("Order placed successfully")
        expect(response[:order]).to be_present
        expect(response[:order].user).to eq(user)
        expect(response[:order].book).to eq(book)
        expect(response[:order].address).to eq(address)
        expect(book.reload.quantity).to eq(8)
      end
    end

    context "when user is not found" do
      it "returns an error response" do
        order_params = { book_id: book.id, address_id: address.id, quantity: 2 }
        response = OrderService.create_order(9999, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("User not found")
      end
    end

    context "when user_id is nil" do
      it "returns an error response" do
        order_params = { book_id: book.id, address_id: address.id, quantity: 2 }
        response = OrderService.create_order(nil, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("User not found")
      end
    end

    context "when book is not found" do
      it "returns an error response" do
        order_params = { book_id: 9999, address_id: address.id, quantity: 2 }
        response = OrderService.create_order(user.id, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Book with ID 9999 not found")
      end
    end

    context "when address is invalid" do
      it "returns an error response" do
        order_params = { book_id: book.id, address_id: 9999, quantity: 2 }
        response = OrderService.create_order(user.id, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Invalid address")
      end
    end

    context "when quantity is zero or negative" do
      it "returns an error response for zero quantity" do
        order_params = { book_id: book.id, address_id: address.id, quantity: 0 }
        response = OrderService.create_order(user.id, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Invalid quantity: must be greater than 0 and less than or equal to available stock (10)")
      end

      it "returns an error response for negative quantity" do
        order_params = { book_id: book.id, address_id: address.id, quantity: -3 }
        response = OrderService.create_order(user.id, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Invalid quantity: must be greater than 0 and less than or equal to available stock (10)")
      end
    end

    context "when quantity exceeds stock" do
      it "returns an error response" do
        order_params = { book_id: book.id, address_id: address.id, quantity: 15 }
        response = OrderService.create_order(user.id, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Invalid quantity: must be greater than 0 and less than or equal to available stock (10)")
      end
    end

    context "when order creation fails due to validation" do
      it "returns an error response for invalid total_price" do
        order_params = {
          book_id: book.id,
          address_id: address.id,
          quantity: 2,
          price_at_purchase: book.discounted_price,
          total_price: 100.0 # Incorrect total price
        }
        response = OrderService.create_order(user.id, order_params)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Total price mismatch: expected 800.0, got 100.0")
      end
    end
  end

  describe ".index_orders" do
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
        response = OrderService.index_orders(user.id)

        expect(response[:success]).to be true
        expect(response[:orders]).to be_present
        expect(response[:orders].count).to eq(2)
        expect(response[:orders]).to include(order1, order2)
      end
    end

    context "when user has no orders" do
      it "returns an error response" do
        response = OrderService.index_orders(user.id)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("No orders found")
      end
    end

    context "when user is not found" do
      it "returns an error response" do
        response = OrderService.index_orders(9999)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("User not found")
      end
    end

    context "when user_id is nil" do
      it "returns an error response" do
        response = OrderService.index_orders(nil)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("User not found")
      end
    end
  end

  describe ".get_order_by_id" do
    let!(:order) do
      user.orders.create!(
        book: book,
        address: address,
        quantity: 2,
        price_at_purchase: book.discounted_price,
        status: "pending",
        total_price: 2 * book.discounted_price
      )
    end

    context "when order exists for the user" do
      it "returns a success response with the order" do
        response = OrderService.get_order_by_id(user.id, order.id)

        expect(response[:success]).to be true
        expect(response[:order]).to eq(order)
        expect(response[:order].user).to eq(user)
        expect(response[:order].book).to eq(book)
        expect(response[:order].address).to eq(address)
      end
    end

    context "when user is not found" do
      it "returns an error response" do
        response = OrderService.get_order_by_id(9999, order.id)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("User not found")
      end
    end

    context "when user_id is nil" do
      it "returns an error response" do
        response = OrderService.get_order_by_id(nil, order.id)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("User not found")
      end
    end

    context "when order is not found" do
      it "returns an error response" do
        response = OrderService.get_order_by_id(user.id, 9999)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Order not found")
      end
    end

    context "when order belongs to another user" do
      let!(:other_user) do
        User.create!(
          name: "Jane Doe",
          email: "jane@gmail.com",
          password: "Password123!",
          mobile_number: "+919876543211"
        )
      end
      let!(:other_order) do
        other_user.orders.create!(
          book: book,
          address: address,
          quantity: 1,
          price_at_purchase: book.discounted_price,
          status: "shipped",
          total_price: book.discounted_price
        )
      end

      it "returns an error response" do
        response = OrderService.get_order_by_id(user.id, other_order.id)

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Order not found")
      end
    end
  end

  describe ".update_order_status" do
    let!(:order) do
      user.orders.create!(
        book: book,
        address: address,
        quantity: 2,
        price_at_purchase: book.discounted_price,
        status: "pending",
        total_price: 2 * book.discounted_price
      )
    end

    context "when the status update is successful" do
      it "updates to 'shipped' and returns a success response" do
        response = OrderService.update_order_status(user.id, order.id, "shipped")

        expect(response[:success]).to be true
        expect(response[:message]).to eq("Order status updated successfully")
        expect(response[:order]).to be_present
        expect(response[:order].status).to eq("shipped")
        expect(order.reload.status).to eq("shipped")
      end

      it "updates to 'cancelled' and restores book quantity" do
        initial_quantity = book.quantity
        response = OrderService.update_order_status(user.id, order.id, "cancelled")

        expect(response[:success]).to be true
        expect(response[:message]).to eq("Order status updated successfully")
        expect(response[:order].status).to eq("cancelled")
        expect(order.reload.status).to eq("cancelled")
        expect(book.reload.quantity).to eq(initial_quantity + 2)
      end
    end

    context "when user is not found" do
      it "returns an error response" do
        response = OrderService.update_order_status(9999, order.id, "shipped")

        expect(response[:success]).to be false
        expect(response[:error]).to eq("User not found")
      end
    end

    context "when user_id is nil" do
      it "returns an error response" do
        response = OrderService.update_order_status(nil, order.id, "shipped")

        expect(response[:success]).to be false
        expect(response[:error]).to eq("User not found")
      end
    end

    context "when order is not found" do
      it "returns an error response" do
        response = OrderService.update_order_status(user.id, 9999, "shipped")

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Order not found")
      end
    end

    context "when order belongs to another user" do
      let!(:other_user) do
        User.create!(
          name: "Jane Doe",
          email: "jane@gmail.com",
          password: "Password123!",
          mobile_number: "+919876543211"
        )
      end
      let!(:other_order) do
        other_user.orders.create!(
          book: book,
          address: address,
          quantity: 1,
          price_at_purchase: book.discounted_price,
          status: "pending",
          total_price: book.discounted_price
        )
      end

      it "returns an error response" do
        response = OrderService.update_order_status(user.id, other_order.id, "shipped")

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Order not found")
      end
    end

    context "when order is not pending" do
      let!(:non_pending_order) do
        user.orders.create!(
          book: book,
          address: address,
          quantity: 1,
          price_at_purchase: book.discounted_price,
          status: "shipped",
          total_price: book.discounted_price
        )
      end

      it "returns an error response" do
        response = OrderService.update_order_status(user.id, non_pending_order.id, "cancelled")

        expect(response[:success]).to be false
        expect(response[:error]).to eq("Only pending orders can be updated")
      end
    end
  end
end
