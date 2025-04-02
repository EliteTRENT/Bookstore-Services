require 'rails_helper'

RSpec.describe "Api::V1::GithubAuth", type: :request do
  describe "POST /api/v1/github_auth" do
    let(:github_code) { "valid_github_code" }
    let(:access_token) { "github_access_token" }
    let(:github_user_data) do
      {
        "id" => 12345,
        "email" => "github_user@example.com",
        "name" => "GitHub User"
      }
    end
    let(:user) do
      User.create!(
        github_id: "12345",
        email: "github_user@example.com",
        name: "GitHub User",
        password: "Password123!",
        mobile_number: "+919876543210"
      )
    end

    before do
      # Stub environment variables
      allow(ENV).to receive(:fetch).with("GITHUB_CLIENT_ID").and_return("test_client_id")
      allow(ENV).to receive(:fetch).with("GITHUB_CLIENT_SECRET").and_return("test_client_secret")
    end

    context "with a valid GitHub code" do
      before do
        # Stub GitHub token exchange
        stub_request(:post, "https://github.com/login/oauth/access_token")
          .with(
            body: {
              "client_id" => "test_client_id",
              "client_secret" => "test_client_secret",
              "code" => github_code
            },
            headers: { "Accept" => "application/json" }
          )
          .to_return(
            status: 200,
            body: { access_token: access_token }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Stub GitHub user data fetch
        stub_request(:get, "https://api.github.com/user")
          .with(
            headers: {
              "Authorization" => "Bearer #{access_token}",
              "User-Agent" => "Rails App"
            }
          )
          .to_return(
            status: 200,
            body: github_user_data.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        # Stub User.from_github
        allow(User).to receive(:from_github).with("12345", "github_user@example.com", "GitHub User").and_return(user)
      end

      it "returns http success with user data and tokens" do
        post "/api/v1/github_auth", params: { code: github_code }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Authentication successful")
        expect(json_response["token"]).to be_present
        expect(json_response["refresh_token"]).to be_present
        expect(json_response["user_id"]).to eq(user.id)
        expect(json_response["user_name"]).to eq(user.name)
        expect(json_response["email"]).to eq(user.email)
        expect(json_response["mobile_number"]).to eq(user.mobile_number)
      end
    end

    context "when GitHub code is missing" do
      it "returns a bad request error" do
        post "/api/v1/github_auth", params: { code: nil }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("GitHub code is required")
      end
    end

    context "when GitHub token exchange fails" do
      before do
        stub_request(:post, "https://github.com/login/oauth/access_token")
          .to_return(
            status: 401,
            body: { error: "invalid_code", error_description: "The code provided is invalid" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns an unauthorized error" do
        post "/api/v1/github_auth", params: { code: "invalid_code" }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid GitHub code")
        expect(json_response["details"]).to eq("The code provided is invalid")
      end
    end

    context "when GitHub user data fetch fails" do
      before do
        stub_request(:post, "https://github.com/login/oauth/access_token")
          .to_return(
            status: 200,
            body: { access_token: access_token }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        stub_request(:get, "https://api.github.com/user")
          .to_return(
            status: 403,
            body: { message: "Forbidden" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns an unauthorized error" do
        post "/api/v1/github_auth", params: { code: github_code }

        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Failed to fetch GitHub user data")
      end
    end

    context "when an unexpected error occurs" do
      before do
        stub_request(:post, "https://github.com/login/oauth/access_token")
          .to_return(
            status: 200,
            body: { access_token: access_token }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        stub_request(:get, "https://api.github.com/user")
          .to_return(
            status: 200,
            body: github_user_data.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        allow(User).to receive(:from_github).and_raise(StandardError.new("Database connection failed"))
      end

      it "returns an unprocessable entity error" do
        post "/api/v1/github_auth", params: { code: github_code }

        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("GitHub authentication error")
        expect(json_response["details"]).to eq("Database connection failed")
      end
    end
  end
end