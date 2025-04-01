require 'rails_helper'

RSpec.describe Api::V1::AddressesController, type: :controller do
  let(:user) { User.create!(name: "Test User", email: "test@gmail.com", password: "Password@123", mobile_number: "9876543210") }
  let(:valid_token) { JsonWebToken.encode({ user_id: user.id }) }
  let(:invalid_token) { "invalid.token.here" }
  let(:valid_address) do
    {
      "street" => "123 Main St",
      "city" => "Springfield",
      "state" => "Illinois",
      "zip_code" => "62701",
      "country" => "USA",
      "type" => "home",
      "is_default" => "true"
    }
  end

  describe "GET #index" do
    context "with authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      context "with addresses" do
        let(:addresses) { [Address.new(valid_address.merge(user_id: user.id))] }

        it "returns the user's addresses" do
          allow(AddressService).to receive(:list_addresses).with(user).and_return(
            { success: true, addresses: addresses }
          )
          get :index
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["user"]["name"]).to eq("Test User")
          expect(json_response["user"]["number"]).to eq("9876543210")
          expect(json_response["addresses"].length).to eq(1)
          expect(json_response["addresses"].first["street"]).to eq("123 Main St")
        end
      end

      context "with no addresses" do
        it "returns an empty address list" do
          allow(AddressService).to receive(:list_addresses).with(user).and_return(
            { success: true, addresses: [] }
          )
          get :index
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["user"]["name"]).to eq("Test User")
          expect(json_response["addresses"]).to be_empty
        end
      end
    end

    context "without authentication" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns an unauthorized response" do
        get :index
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing token")
      end
    end
  end

  describe "POST #create" do
    context "with authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      context "with valid address parameters" do
        let(:address_params) { { address: valid_address.transform_keys(&:to_sym) } }
        let(:permitted_params) do
          ActionController::Parameters.new(valid_address).permit(:street, :city, :state, :zip_code, :country, :type, :is_default)
        end

        it "creates an address and returns a success response" do
          allow(AddressService).to receive(:add_address).with(user, permitted_params).and_return(
            { success: true, message: "Address added successfully", address: Address.new(valid_address.merge("user_id" => user.id)) }
          )
          post :create, params: address_params
          expect(response).to have_http_status(:created)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Address added successfully")
          expect(json_response["address"]["street"]).to eq("123 Main St")
        end
      end

      context "with invalid address parameters" do
        let(:invalid_address_params) { { address: valid_address.merge("street" => "").transform_keys(&:to_sym) } }
        let(:permitted_invalid_params) do
          ActionController::Parameters.new(valid_address.merge("street" => "")).permit(:street, :city, :state, :zip_code, :country, :type, :is_default)
        end

        it "returns an error response" do
          allow(AddressService).to receive(:add_address).with(user, permitted_invalid_params).and_return(
            { success: false, error: ["Street can't be blank"] }
          )
          post :create, params: invalid_address_params
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq(["Street can't be blank"])
        end
      end

      context "with invalid address type" do
        let(:invalid_type_params) { { address: valid_address.merge("type" => "invalid").transform_keys(&:to_sym) } }
        let(:permitted_invalid_type_params) do
          ActionController::Parameters.new(valid_address.merge("type" => "invalid")).permit(:street, :city, :state, :zip_code, :country, :type, :is_default)
        end

        it "returns an error response for invalid type" do
          allow(AddressService).to receive(:add_address).with(user, permitted_invalid_type_params).and_return(
            { success: false, error: ["Type must be 'home', 'work', or 'other'"] }
          )
          post :create, params: invalid_type_params
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq(["Type must be 'home', 'work', or 'other'"])
        end
      end
    end

    context "without authentication" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns an unauthorized response" do
        post :create, params: { address: valid_address }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing token")
      end
    end
  end

  describe "PATCH #update" do
    context "with authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      context "with valid address update" do
        let(:update_params) { { id: 1, address: { street: "456 Elm St" } } }
        let(:permitted_update_params) { ActionController::Parameters.new("street" => "456 Elm St").permit(:street, :city, :state, :zip_code, :country, :type, :is_default) }

        it "updates the address and returns a success response" do
          allow(AddressService).to receive(:update_address).with(user, "1", permitted_update_params).and_return(
            { success: true, message: "Address updated successfully", address: Address.new(valid_address.merge("street" => "456 Elm St", "user_id" => user.id)) }
          )
          patch :update, params: update_params
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq("Address updated successfully")
          expect(json_response["address"]["street"]).to eq("456 Elm St")
        end
      end

      context "with invalid address update" do
        let(:invalid_update_params) { { id: 1, address: { street: "" } } }
        let(:permitted_invalid_update_params) { ActionController::Parameters.new("street" => "").permit(:street, :city, :state, :zip_code, :country, :type, :is_default) }

        it "returns an error response" do
          allow(AddressService).to receive(:update_address).with(user, "1", permitted_invalid_update_params).and_return(
            { success: false, error: ["Street can't be blank"] }
          )
          patch :update, params: invalid_update_params
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq(["Street can't be blank"])
        end
      end

      context "with non-existent address" do
        let(:update_params) { { id: 999, address: { street: "456 Elm St" } } }
        let(:permitted_update_params) { ActionController::Parameters.new("street" => "456 Elm St").permit(:street, :city, :state, :zip_code, :country, :type, :is_default) }

        it "returns an error response" do
          allow(AddressService).to receive(:update_address).with(user, "999", permitted_update_params).and_return(
            { success: false, error: ["Address not found"] }
          )
          patch :update, params: update_params
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["message"]).to eq(["Address not found"])
        end
      end
    end

    context "without authentication" do
      before do
        request.headers["Authorization"] = nil
      end

      it "returns an unauthorized response" do
        patch :update, params: { id: 1, address: { street: "456 Elm St" } }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Missing token")
      end
    end
  end

  describe "DELETE #destroy" do
    context "with authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{valid_token}"
        allow(controller).to receive(:authenticate_request).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      context "with a valid address" do
        it "deletes the address and returns a success response" do
          allow(AddressService).to receive(:remove_address).with(user, "1").and_return(
            { success: true, message: "Address removed successfully" }
          )
          delete :destroy, params: { id: 1 }
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["success"]).to be true
          expect(json_response["message"]).to eq("Address removed successfully")
        end
      end

      context "with an address linked to orders" do
        it "returns an error response" do
          allow(AddressService).to receive(:remove_address).with(user, "1").and_return(
            { success: false, message: "Cannot delete address because it is linked to existing orders" }
          )
          delete :destroy, params: { id: 1 }
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["success"]).to be false
          expect(json_response["message"]).to eq("Cannot delete address because it is linked to existing orders")
        end
      end

      context "with a non-existent address" do
        it "returns an error response" do
          allow(AddressService).to receive(:remove_address).with(user, "999").and_return(
            { success: false, message: "Address not found" }
          )
          delete :destroy, params: { id: 999 }
          expect(response).to have_http_status(:ok)
          json_response = JSON.parse(response.body)
          expect(json_response["success"]).to be false
          expect(json_response["message"]).to eq("Address not found")
        end
      end
    end

    context "with invalid authentication" do
      before do
        request.headers["Authorization"] = "Bearer #{invalid_token}"
        # Stub authenticate_request to simulate the invalid token response without running the real method
        allow(controller).to receive(:authenticate_request) do
          controller.render json: { error: "Session expired" }, status: :unauthorized
          nil # Ensure the action doesn't proceed
        end
      end

      it "returns an unauthorized response" do
        delete :destroy, params: { id: 1 }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Session expired")
      end
    end
  end
end