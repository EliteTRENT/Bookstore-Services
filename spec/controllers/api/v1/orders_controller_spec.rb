require 'rails_helper'

RSpec.describe Api::V1::OrdersController, type: :controller do
  let(:valid_token) { "valid.jwt.token" }
  let(:invalid_token) { "invalid.jwt.token" }
  let(:user) { instance_double(User, id: 1, email: "test@example.com") }
  let(:book) { instance_double(Book, id: 1, quantity: 10) }
  let(:address) { instance_double(Address, id: 1) }
  let(:order) { instance_double(Order, id: 1, user_id: user.id, book_id: book.id, address_id: address.id, quantity: 2, price_at_purchase: 10.0, total_price: 20.0, status: "pending") }

  before do
    # Stub authenticate_request to allow tests to proceed
    allow(controller).to receive(:authenticate_request).and_return(true)
  end

  describe "POST #create" do
    let(:order_params) { { order: { user_id: user.id, book_id: book.id, address_id: address.id, quantity: 2, price_at_purchase: 10.0, total_price: 20.0 } } }

    context "with valid token and params" do
      before do
        allow(OrderService).to receive(:create_order).with(valid_token, anything).and_return(
          { success: true, message: "Order placed successfully", order: order }
        )
      end

      it "creates an order and returns a success response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        post :create, params: order_params
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["message"]).to eq("Order placed successfully")
        expect(json_response["order"]).to be_present
      end
    end

    context "with invalid token" do
      before do
        allow(OrderService).to receive(:create_order).with(invalid_token, anything).and_return(
          { success: false, error: "Invalid token" }
        )
      end

      it "returns an unauthorized response" do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        post :create, params: order_params
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid token")
      end
    end

    context "with missing user" do
      before do
        allow(OrderService).to receive(:create_order).with(valid_token, anything).and_return(
          { success: false, error: "User not found" }
        )
      end

      it "returns a not found response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        post :create, params: order_params
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("User not found")
      end
    end

    context "with validation errors" do
      before do
        allow(OrderService).to receive(:create_order).with(valid_token, anything).and_return(
          { success: false, error: ["Quantity cannot exceed available book quantity"] }
        )
      end

      it "returns an unprocessable entity response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        post :create, params: order_params
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to eq(["Quantity cannot exceed available book quantity"])
      end
    end
  end

  describe "GET #index" do
    context "with valid token" do
      before do
        allow(OrderService).to receive(:index_orders).with(valid_token).and_return(
          { success: true, orders: [order] }
        )
      end

      it "returns a list of orders" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        get :index
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["orders"]).to be_present
        expect(json_response["orders"].length).to eq(1)
      end
    end

    context "with invalid token" do
      before do
        allow(OrderService).to receive(:index_orders).with(invalid_token).and_return(
          { success: false, error: "Invalid token" }
        )
      end

      it "returns an unauthorized response" do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        get :index
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid token")
      end
    end

    context "with no orders" do
      before do
        allow(OrderService).to receive(:index_orders).with(valid_token).and_return(
          { success: false, error: "No orders found" }
        )
      end

      it "returns an unprocessable entity response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        get :index
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to eq("No orders found")
      end
    end
  end

  describe "GET #show" do
    context "with valid token and order id" do
      before do
        allow(OrderService).to receive(:get_order_by_id).with(valid_token, "1").and_return(
          { success: true, order: order }
        )
      end

      it "returns the order" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        get :show, params: { id: 1 }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["order"]).to be_present
      end
    end

    context "with invalid token" do
      before do
        allow(OrderService).to receive(:get_order_by_id).with(invalid_token, "1").and_return(
          { success: false, error: "Invalid token" }
        )
      end

      it "returns an unauthorized response" do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        get :show, params: { id: 1 }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid token")
      end
    end

    context "with non-existent order" do
      before do
        allow(OrderService).to receive(:get_order_by_id).with(valid_token, "1").and_return(
          { success: false, error: "Order not found" }
        )
      end

      it "returns a not found response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        get :show, params: { id: 1 }
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Order not found")
      end
    end
  end

  describe "PUT #update_status" do
    context "with valid token and pending order" do
      before do
        allow(OrderService).to receive(:update_order_status).with(valid_token, "1", "cancelled").and_return(
          { success: true, message: "Order status updated successfully", order: order }
        )
      end

      it "updates the order status and returns a success response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        put :update_status, params: { id: 1, status: "cancelled" }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Order status updated successfully")
        expect(json_response["order"]).to be_present
      end
    end

    context "with invalid token" do
      before do
        allow(OrderService).to receive(:update_order_status).with(invalid_token, "1", "cancelled").and_return(
          { success: false, error: "Invalid token" }
        )
      end

      it "returns an unauthorized response" do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        put :update_status, params: { id: 1, status: "cancelled" }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid token")
      end
    end

    context "with non-existent order" do
      before do
        allow(OrderService).to receive(:update_order_status).with(valid_token, "1", "cancelled").and_return(
          { success: false, error: "Order not found" }
        )
      end

      it "returns a not found response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        put :update_status, params: { id: 1, status: "cancelled" }
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Order not found")
      end
    end

    context "with non-pending order" do
      before do
        allow(OrderService).to receive(:update_order_status).with(valid_token, "1", "cancelled").and_return(
          { success: false, error: "Only pending orders can be cancelled" }
        )
      end

      it "returns an unprocessable entity response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        put :update_status, params: { id: 1, status: "cancelled" }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to eq(["Only pending orders can be cancelled"])
      end
    end

    context "with book update failure" do
      before do
        allow(OrderService).to receive(:update_order_status).with(valid_token, "1", "cancelled").and_return(
          { success: false, error: ["Quantity can't be negative"] }
        )
      end

      it "returns an unprocessable entity response" do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        put :update_status, params: { id: 1, status: "cancelled" }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to eq(["Quantity can't be negative"])
      end
    end
  end
end