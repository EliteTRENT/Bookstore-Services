require 'rails_helper'

RSpec.describe Api::V1::OrdersController, type: :controller do
  let(:user) { User.create!(name: "Test User", email: "test@gmail.com", password: "Password@123", mobile_number: "9876543210") }
  let(:book) { Book.create!(name: "Test Book", author: "Author", mrp: 20.0, discounted_price: 10.0, quantity: 10) }
  let(:address) { Address.create!(user: user, street: "123 Test St", city: "Test City", state: "Test State", zip_code: "12345", country: "Test Country", type: "home") }
  let(:order) { Order.new(id: 1, user_id: user.id, book_id: book.id, address_id: address.id, quantity: 2, price_at_purchase: 10.0, total_price: 20.0, status: "pending") }
  let(:valid_token) { JsonWebToken.encode({ user_id: user.id }) }
  let(:invalid_token) { "invalid.jwt.token" }

  describe "POST #create" do
    let(:order_params) { { order: { book_id: book.id, address_id: address.id, quantity: 2, price_at_purchase: 10.0, total_price: 20.0 } } }

    context "with valid token and params" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request) do
          controller.instance_variable_set(:@current_user, user)
        end
        allow(OrderService).to receive(:create_order).with(user.id, anything).and_return(
          { success: true, message: "Order placed successfully", order: order }
        )
      end

      it "creates an order and returns a success response" do
        post :create, params: order_params
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Order placed successfully")
        expect(json_response["order"]).to be_present
      end
    end

    context "with invalid token" do
      before do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_raise(JWT::DecodeError, "Invalid token")
      end

      it "returns an unauthorized response" do
        post :create, params: order_params
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Session expired")
      end
    end

    context "with missing user" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request) do
          controller.instance_variable_set(:@current_user, user)
        end
        allow(OrderService).to receive(:create_order).with(user.id, anything).and_return(
          { success: false, error: "User not found" }
        )
      end

      it "returns a not found response" do
        post :create, params: order_params
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("User not found")
      end
    end

    context "with validation errors" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request) do
          controller.instance_variable_set(:@current_user, user)
        end
        allow(OrderService).to receive(:create_order).with(user.id, anything).and_return(
          { success: false, error: "Invalid quantity: must be greater than 0 and less than or equal to available stock (10)" }
        )
      end

      it "returns an unprocessable entity response" do
        post :create, params: order_params
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid quantity: must be greater than 0 and less than or equal to available stock (10)")
      end
    end
  end

  describe "GET #index" do
    context "with valid token" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request) do
          controller.instance_variable_set(:@current_user, user)
        end
        allow(OrderService).to receive(:index_orders).with(user.id).and_return(
          { success: true, orders: [order] }
        )
      end

      it "returns a list of orders" do
        get :index
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["orders"]).to be_present
        expect(json_response["orders"].length).to eq(1)
      end
    end

    context "with invalid token" do
      before do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_raise(JWT::DecodeError, "Invalid token")
      end

      it "returns an unauthorized response" do
        get :index
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Session expired")
      end
    end

    context "with no orders" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request) do
          controller.instance_variable_set(:@current_user, user)
        end
        allow(OrderService).to receive(:index_orders).with(user.id).and_return(
          { success: false, error: "No orders found" }
        )
      end

      it "returns an unprocessable entity response" do
        get :index
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("No orders found")
      end
    end
  end

  describe "GET #show" do
    context "with valid token and order id" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request) do
          controller.instance_variable_set(:@current_user, user)
        end
        allow(OrderService).to receive(:get_order_by_id).with(user.id, "1").and_return(
          { success: true, order: order }
        )
      end

      it "returns the order" do
        get :show, params: { id: 1 }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["order"]).to be_present
      end
    end

    context "with invalid token" do
      before do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_raise(JWT::DecodeError, "Invalid token")
      end

      it "returns an unauthorized response" do
        get :show, params: { id: 1 }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Session expired")
      end
    end

    context "with non-existent order" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request) do
          controller.instance_variable_set(:@current_user, user)
        end
        allow(OrderService).to receive(:get_order_by_id).with(user.id, "1").and_return(
          { success: false, error: "Order not found" }
        )
      end

      it "returns a not found response" do
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
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request) do
          controller.instance_variable_set(:@current_user, user)
        end
        allow(OrderService).to receive(:update_order_status).with(user.id, "1", "cancelled").and_return(
          { success: true, message: "Order status updated successfully", order: order }
        )
      end

      it "updates the order status and returns a success response" do
        put :update_status, params: { id: 1, status: "cancelled" }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Order status updated successfully")
        expect(json_response["order"]).to be_present
      end
    end

    context "with invalid token" do
      before do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_raise(JWT::DecodeError, "Invalid token")
      end

      it "returns an unauthorized response" do
        put :update_status, params: { id: 1, status: "cancelled" }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Session expired")
      end
    end

    context "with non-existent order" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request) do
          controller.instance_variable_set(:@current_user, user)
        end
        allow(OrderService).to receive(:update_order_status).with(user.id, "1", "cancelled").and_return(
          { success: false, error: "Order not found" }
        )
      end

      it "returns a not found response" do
        put :update_status, params: { id: 1, status: "cancelled" }
        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Order not found")
      end
    end

    context "with non-pending order" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request) do
          controller.instance_variable_set(:@current_user, user)
        end
        allow(OrderService).to receive(:update_order_status).with(user.id, "1", "cancelled").and_return(
          { success: false, error: "Only pending orders can be updated" }
        )
      end

      it "returns an unprocessable entity response" do
        put :update_status, params: { id: 1, status: "cancelled" }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Only pending orders can be updated")
      end
    end

    context "with book update failure" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request) do
          controller.instance_variable_set(:@current_user, user)
        end
        allow(OrderService).to receive(:update_order_status).with(user.id, "1", "cancelled").and_return(
          { success: false, error: "Quantity can't be negative" }
        )
      end

      it "returns an unprocessable entity response" do
        put :update_status, params: { id: 1, status: "cancelled" }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Quantity can't be negative")
      end
    end
  end
end