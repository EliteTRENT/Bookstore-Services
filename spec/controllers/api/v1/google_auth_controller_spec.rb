require 'rails_helper'

RSpec.describe Api::V1::GoogleAuthController, type: :controller do
  let(:google_client_id) { "892883759524-crgr5ag4eu4o21c1ginihfbsouhm9u1v.apps.googleusercontent.com" }
  let(:valid_google_token) { "valid.google.token" }
  let(:invalid_google_token) { "invalid.google.token" }
  let(:google_payload) do
    {
      "sub" => "123456789",
      "email" => "test@example.com",
      "name" => "Test User"
    }
  end
  let(:user) { User.new(id: 1, google_id: "123456789", email: "test@example.com", name: "Test User", mobile_number: "9876543210") }
  let(:jwt_token) { "jwt.token.here" }

  describe "POST #create" do
    context "with a valid Google token" do
      before do
        allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_ID").and_return(google_client_id)
        validator = instance_double(GoogleIDToken::Validator)
        allow(GoogleIDToken::Validator).to receive(:new).and_return(validator)
        allow(validator).to receive(:check).with(valid_google_token, google_client_id).and_return(google_payload)
        allow(User).to receive(:find_by).with(google_id: "123456789").and_return(nil)
        allow(User).to receive(:find_by).with(email: "test@example.com").and_return(nil)
        allow(User).to receive(:create!).with(
          google_id: "123456789",
          email: "test@example.com",
          name: "Test User"
        ).and_return(user)
        allow(JsonWebToken).to receive(:encode).with(
          { id: user.id, name: user.name, email: user.email }
        ).and_return(jwt_token)
      end

      it "creates a new user and returns a success response with JWT token" do
        post :create, params: { token: valid_google_token }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Authentication successful")
        expect(json_response["token"]).to eq(jwt_token)
        expect(json_response["user_id"]).to eq(user.id)
        expect(json_response["user_name"]).to eq("Test User")
        expect(json_response["email"]).to eq("test@example.com")
        expect(json_response["mobile_number"]).to eq("9876543210")
      end
    end

    context "with an existing user by google_id" do
      before do
        allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_ID").and_return(google_client_id)
        validator = instance_double(GoogleIDToken::Validator)
        allow(GoogleIDToken::Validator).to receive(:new).and_return(validator)
        allow(validator).to receive(:check).with(valid_google_token, google_client_id).and_return(google_payload)
        allow(User).to receive(:find_by).with(google_id: "123456789").and_return(user)
        allow(user).to receive(:update!)
        allow(JsonWebToken).to receive(:encode).with(
          { id: user.id, name: user.name, email: user.email }
        ).and_return(jwt_token)
      end

      it "returns a success response with JWT token for existing user" do
        post :create, params: { token: valid_google_token }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Authentication successful")
        expect(json_response["token"]).to eq(jwt_token)
        expect(json_response["user_id"]).to eq(user.id)
        expect(json_response["user_name"]).to eq("Test User")
        expect(json_response["email"]).to eq("test@example.com")
      end
    end

    context "with an existing user by email (no google_id)" do
      let(:existing_user) { User.new(id: 2, email: "test@example.com", name: "Test User", mobile_number: "9876543210") }

      before do
        allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_ID").and_return(google_client_id)
        validator = instance_double(GoogleIDToken::Validator)
        allow(GoogleIDToken::Validator).to receive(:new).and_return(validator)
        allow(validator).to receive(:check).with(valid_google_token, google_client_id).and_return(google_payload)
        allow(User).to receive(:find_by).with(google_id: "123456789").and_return(nil)
        allow(User).to receive(:find_by).with(email: "test@example.com").and_return(existing_user)
        allow(existing_user).to receive(:update!).with(google_id: "123456789").and_return(true)
        allow(JsonWebToken).to receive(:encode).with(
          { id: existing_user.id, name: existing_user.name, email: existing_user.email }
        ).and_return(jwt_token)
      end

      it "updates the user with google_id and returns a success response" do
        post :create, params: { token: valid_google_token }
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Authentication successful")
        expect(json_response["token"]).to eq(jwt_token)
        expect(json_response["user_id"]).to eq(existing_user.id)
        expect(json_response["user_name"]).to eq("Test User")
        expect(json_response["email"]).to eq("test@example.com")
      end
    end

    context "with an invalid Google token" do
      before do
        allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_ID").and_return(google_client_id)
        validator = instance_double(GoogleIDToken::Validator)
        allow(GoogleIDToken::Validator).to receive(:new).and_return(validator)
        allow(validator).to receive(:check).with(invalid_google_token, google_client_id)
          .and_raise(GoogleIDToken::ValidationError, "Token expired")
      end

      it "returns an unauthorized response" do
        post :create, params: { token: invalid_google_token }
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid token")
        expect(json_response["details"]).to eq("Token expired")
      end
    end

    context "when user creation fails" do
      before do
        allow(ENV).to receive(:fetch).with("GOOGLE_CLIENT_ID").and_return(google_client_id)
        validator = instance_double(GoogleIDToken::Validator)
        allow(GoogleIDToken::Validator).to receive(:new).and_return(validator)
        allow(validator).to receive(:check).with(valid_google_token, google_client_id).and_return(google_payload)
        allow(User).to receive(:find_by).with(google_id: "123456789").and_return(nil)
        allow(User).to receive(:find_by).with(email: "test@example.com").and_return(nil)
        allow(User).to receive(:create!).with(
          google_id: "123456789",
          email: "test@example.com",
          name: "Test User"
        ).and_raise(ActiveRecord::RecordInvalid.new(user), "Email can't be blank")
      end

      it "returns an unprocessable entity response" do
        post :create, params: { token: valid_google_token }
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Failed to create or update user")
        expect(json_response["details"]).to eq("Email can't be blank")
      end
    end
  end
end
