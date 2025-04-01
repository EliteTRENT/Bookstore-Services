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

    it "returns http success" do
      post "/api/v1/github_auth", params: { code: github_code }

      expect(response).to have_http_status(:success)
    end
  end
end