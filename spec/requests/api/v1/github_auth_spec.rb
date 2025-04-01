require 'rails_helper'

RSpec.describe "Api::V1::GithubAuths", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/api/v1/github_auth/create"
      expect(response).to have_http_status(:success)
    end
  end

end
