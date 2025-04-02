require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  # Use an anonymous controller to test ApplicationController behavior
  controller do
    # Only apply restrict_to_admin when explicitly testing that behavior
    def index
      render json: { message: "Success" }, status: :ok
    end
  end

  let(:user) { User.create!(name: "Test User", email: "test@gmail.com", password: "Password@123", mobile_number: "9876543210") }
  let(:admin_user) { User.create!(name: "Admin User", email: "admin@gmail.com", password: "Password@123", mobile_number: "9123456789", role: "admin") }
  let(:valid_token) { JsonWebToken.encode({ user_id: user.id }) }
  let(:admin_token) { JsonWebToken.encode({ user_id: admin_user.id }) }
  let(:invalid_token) { "invalid.token.here" }

  describe "#authenticate_request" do
    context "with a valid token" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
      end

      it "authenticates the user and proceeds with the request" do
        allow(JsonWebToken).to receive(:decode).with(valid_token).and_return({ "user_id" => user.id })
        allow(User).to receive(:find_by).with(id: user.id).and_return(user)
        get :index
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Success")
      end

      context "with user_id mismatch in params" do
        it "returns unauthorized if user_id in params does not match the authenticated user" do
          allow(JsonWebToken).to receive(:decode).with(valid_token).and_return({ "user_id" => user.id })
          allow(User).to receive(:find_by).with(id: user.id).and_return(user)
          get :index, params: { user_id: (user.id + 1).to_s }
          expect(response).to have_http_status(:unauthorized)
          json_response = JSON.parse(response.body)
          expect(json_response["error"]).to eq("Session expired")
        end
      end
    end

    context "with an invalid token" do
      before do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
      end

      it "returns unauthorized with a decode error" do
        allow(JsonWebToken).to receive(:decode).with(invalid_token).and_raise(JWT::DecodeError)
        get :index
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Session expired")
      end
    end

    context "with no token" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns unauthorized with missing token error" do
        get :index
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing token")
      end
    end

    context "with a token but no matching user" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
      end

      it "returns unauthorized with session expired error" do
        allow(JsonWebToken).to receive(:decode).with(valid_token).and_return({ "user_id" => user.id })
        allow(User).to receive(:find_by).with(id: user.id).and_return(nil)
        get :index
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Session expired")
      end
    end
  end

  describe "#restrict_to_admin" do
    # Redefine the controller with restrict_to_admin for these tests
    controller do
      before_action :restrict_to_admin, only: :index

      def index
        render json: { message: "Success" }, status: :ok
      end
    end

    context "with an admin user" do
      before do
        request.headers["Authorization"] = "Bearer #{admin_token}"
        allow(JsonWebToken).to receive(:decode).with(admin_token).and_return({ "user_id" => admin_user.id })
        allow(User).to receive(:find_by).with(id: admin_user.id).and_return(admin_user)
      end

      it "allows access and proceeds with the request" do
        get :index
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Success")
      end
    end

    context "with a non-admin user" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(JsonWebToken).to receive(:decode).with(valid_token).and_return({ "user_id" => user.id })
        allow(User).to receive(:find_by).with(id: user.id).and_return(user)
      end

      it "returns forbidden with admin access required error" do
        get :index
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Admin access required")
      end
    end

    context "with no current_user set" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(JsonWebToken).to receive(:decode).with(valid_token).and_return({ "user_id" => user.id })
        allow(User).to receive(:find_by).with(id: user.id).and_return(nil)
      end

      it "returns unauthorized before reaching restrict_to_admin" do
        get :index
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Session expired")
      end
    end
  end
end