require 'rails_helper'

RSpec.describe JsonWebToken, type: :service do
  let(:user_payload) { { user_id: 1, name: "John Doe" } }
  let(:secret_key) { "your-secret-key-here" }
  let(:refresh_secret_key) { "your-refresh-secret-key-here" }

  before do
    # Stub the environment variables for consistent testing
    allow(ENV).to receive(:[]).with("SECRET_KEY").and_return(secret_key)
    allow(ENV).to receive(:[]).with("REFRESH_SECRET_KEY").and_return(refresh_secret_key)
    # Ensure the class constant uses the stubbed value
    stub_const("JsonWebToken::SECRET_KEY", secret_key)
    stub_const("JsonWebToken::REFRESH_SECRET_KEY", refresh_secret_key)
  end

  describe ".encode" do
    context "with valid payload" do
      it "encodes an access token successfully" do
        token = JsonWebToken.encode(user_payload)
        expect(token).to be_a(String)
        expect(token.split('.').length).to eq(3) # JWT has 3 parts: header, payload, signature
        decoded = JWT.decode(token, secret_key, true, algorithm: "HS256")[0]
        expect(decoded["user_id"]).to eq(user_payload[:user_id])
        expect(decoded["name"]).to eq(user_payload[:name])
        expect(decoded["exp"]).to be_within(5).of(1.minute.from_now.to_i)
      end

      it "encodes with a custom expiration" do
        custom_expiration = 5.minutes.from_now
        token = JsonWebToken.encode(user_payload, expiration: custom_expiration)
        expect(token).to be_a(String)
        decoded = JWT.decode(token, secret_key, true, algorithm: "HS256")[0]
        expect(decoded["exp"]).to eq(custom_expiration.to_i)
      end
    end
  end

  describe ".encode_refresh" do
    context "with valid payload" do
      it "encodes a refresh token successfully" do
        token = JsonWebToken.encode_refresh(user_payload)
        expect(token).to be_a(String)
        expect(token.split('.').length).to eq(3)
        decoded = JWT.decode(token, refresh_secret_key, true, algorithm: "HS256")[0]
        expect(decoded["user_id"]).to eq(user_payload[:user_id])
        expect(decoded["name"]).to eq(user_payload[:name])
        expect(decoded["exp"]).to be_within(5).of(30.days.from_now.to_i)
      end

      it "encodes with a custom expiration" do
        custom_expiration = 1.day.from_now
        token = JsonWebToken.encode_refresh(user_payload, expiration: custom_expiration)
        decoded = JWT.decode(token, refresh_secret_key, true, algorithm: "HS256")[0]
        expect(decoded["exp"]).to eq(custom_expiration.to_i)
      end
    end
  end

  describe ".decode" do
    let(:valid_token) { JsonWebToken.encode(user_payload) }

    context "with a valid access token" do
      it "decodes the token successfully" do
        result = JsonWebToken.decode(valid_token)
        expect(result).to be_a(HashWithIndifferentAccess)
        expect(result[:user_id]).to eq(user_payload[:user_id])
        expect(result[:name]).to eq(user_payload[:name])
        expect(result[:exp]).to be_present
      end
    end

    context "with an expired access token" do
      it "returns :expired" do
        expired_token = JsonWebToken.encode(user_payload, expiration: 1.minute.ago)
        result = JsonWebToken.decode(expired_token)
        expect(result).to eq(:expired)
      end
    end

    context "with an invalid access token" do
      it "returns nil for a malformed token" do
        result = JsonWebToken.decode("invalid.token.here")
        expect(result).to be_nil
      end

      it "returns nil for a token with wrong secret" do
        wrong_secret_token = JWT.encode(user_payload, "wrong-secret", "HS256")
        result = JsonWebToken.decode(wrong_secret_token)
        expect(result).to be_nil
      end
    end
  end

  describe ".decode_refresh" do
    let(:valid_refresh_token) { JsonWebToken.encode_refresh(user_payload) }

    context "with a valid refresh token" do
      it "decodes the refresh token successfully" do
        result = JsonWebToken.decode_refresh(valid_refresh_token)
        expect(result).to be_a(HashWithIndifferentAccess)
        expect(result[:user_id]).to eq(user_payload[:user_id])
        expect(result[:name]).to eq(user_payload[:name])
        expect(result[:exp]).to be_present
      end
    end

    context "with an expired refresh token" do
      it "returns :expired" do
        expired_refresh_token = JsonWebToken.encode_refresh(user_payload, expiration: 1.day.ago)
        result = JsonWebToken.decode_refresh(expired_refresh_token)
        expect(result).to eq(:expired)
      end
    end

    context "with an invalid refresh token" do
      it "returns nil for a malformed token" do
        result = JsonWebToken.decode_refresh("invalid.token.here")
        expect(result).to be_nil
      end

      it "returns nil for a token with wrong secret" do
        wrong_secret_token = JWT.encode(user_payload, "wrong-secret", "HS256")
        result = JsonWebToken.decode_refresh(wrong_secret_token)
        expect(result).to be_nil
      end
    end
  end

  describe ".refresh" do
    let(:valid_refresh_token) { JsonWebToken.encode_refresh(user_payload) }

    context "with a valid refresh token" do
      it "generates a new access token successfully" do
        result = JsonWebToken.refresh(valid_refresh_token)
        expect(result).to be_a(Hash)
        expect(result[:access_token]).to be_a(String)
        expect(result[:access_token].split('.').length).to eq(3)

        decoded = JsonWebToken.decode(result[:access_token])
        expect(decoded[:user_id]).to eq(user_payload[:user_id])
        expect(decoded[:exp]).to be_within(5).of(1.minute.from_now.to_i)
        expect(decoded[:name]).to be_nil # Only user_id is carried over
      end
    end

    context "with an expired refresh token" do
      it "returns nil" do
        expired_refresh_token = JsonWebToken.encode_refresh(user_payload, expiration: 1.day.ago)
        result = JsonWebToken.refresh(expired_refresh_token)
        expect(result).to be_nil
      end
    end

    context "with an invalid refresh token" do
      it "returns nil for a malformed token" do
        result = JsonWebToken.refresh("invalid.token.here")
        expect(result).to be_nil
      end

      it "returns nil for a token with wrong secret" do
        wrong_secret_token = JWT.encode(user_payload, "wrong-secret", "HS256")
        result = JsonWebToken.refresh(wrong_secret_token)
        expect(result).to be_nil
      end
    end
  end
end