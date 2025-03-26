require 'rails_helper'

RSpec.describe Api::V1::UsersController, type: :controller do
  describe "POST #signup" do
    let(:valid_attributes) do
      {
        user: {
          name: "John Doe",
          email: "john.doe@gmail.com",
          password: "Password@123",
          mobile_number: "9876543210"
        }
      }
    end

    let(:invalid_attributes) do
      {
        user: {
          name: "", # Invalid: name is blank
          email: "john.doe@gmail.com",
          password: "Password@123",
          mobile_number: "9876543210"
        }
      }
    end

    context "with valid attributes" do
      it "creates a user and returns a success response" do
        post :signup, params: valid_attributes
        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("User created successfully")
        expect(json_response["user"]["email"]).to eq("john.doe@gmail.com")
        expect(User.count).to eq(1)
      end
    end

    context "with invalid attributes" do
      it "returns an error response" do
        post :signup, params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Name can't be blank")
      end
    end
  end

  describe "POST #login" do
    let!(:user) do
      User.create!(
        name: "John Doe",
        email: "john.doe@gmail.com",
        password: "Password@123",
        mobile_number: "9876543210"
      )
    end

    let(:valid_login_params) do
      {
        user: {
          email: "john.doe@gmail.com",
          password: "Password@123"
        }
      }
    end

    let(:invalid_login_params) do
      {
        user: {
          email: "john.doe@gmail.com",
          password: "WrongPass@123"
        }
      }
    end

    context "with valid credentials" do
      it "logs in successfully and returns a token" do
        post :login, params: valid_login_params
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Login successful")
        expect(json_response["token"]).not_to be_nil
        expect(json_response["user_id"]).to eq(user.id)
        expect(json_response["user_name"]).to eq("John Doe")
        expect(json_response["email"]).to eq("john.doe@gmail.com")
        expect(json_response["mobile_number"]).to eq("9876543210")
      end
    end

    context "with invalid credentials" do
      it "returns an error response for wrong password" do
        post :login, params: invalid_login_params
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to eq("Wrong password")
      end
    end

    context "with unregistered email" do
      let(:unregistered_params) do
        {
          user: {
            email: "unknown@gmail.com",
            password: "Password@123"
          }
        }
      end

      it "returns an error response" do
        post :login, params: unregistered_params
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to eq("Email is not registered")
      end
    end

    context "when an unexpected error occurs" do
      before do
        allow(UserService).to receive(:login).and_raise(StandardError, "Unexpected error")
      end

      it "returns an internal server error" do
        post :login, params: valid_login_params
        expect(response).to have_http_status(:internal_server_error)
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Internal server error")
        expect(json_response["details"]).to eq("Unexpected error")
      end
    end
  end

  describe "POST #forgetPassword" do
    let!(:user) do
      User.create!(
        name: "John Doe",
        email: "john.doe@gmail.com",
        password: "Password@123",
        mobile_number: "9876543210"
      )
    end

    let(:valid_forget_params) do
      {
        user: {
          email: "john.doe@gmail.com"
        }
      }
    end

    let(:invalid_forget_params) do
      {
        user: {
          email: "unknown@gmail.com"
        }
      }
    end

    context "with a registered email" do
      before do
        allow(UserMailer).to receive(:enqueue_otp_email).and_return(true)
      end

      it "initiates password reset and returns OTP" do
        post :forgetPassword, params: valid_forget_params
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["message"]).to eq("OTP has been sent to john.doe@gmail.com, check your inbox")
        expect(json_response["otp"]).to be_a(Integer)
        expect(json_response["otp"]).to be_between(100000, 999999)
        expect(json_response["user_id"]).to eq(user.id)
      end
    end

    context "with an unregistered email" do
      it "returns an error response" do
        post :forgetPassword, params: invalid_forget_params
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to eq("Email is not registered")
      end
    end

    context "when email enqueue fails" do
      before do
        allow(UserMailer).to receive(:enqueue_otp_email).and_raise(StandardError, "RabbitMQ connection failed")
      end

      it "returns an error response" do
        post :forgetPassword, params: valid_forget_params
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to eq("Failed to send OTP, please try again")
      end
    end
  end

  describe "POST #resetPassword" do
    let!(:user) do
      User.create!(
        name: "John Doe",
        email: "john.doe@gmail.com",
        password: "Password@123",
        mobile_number: "9876543210"
      )
    end

    before do
      # Simulate a prior forgetPassword call to set OTP
      allow(UserMailer).to receive(:enqueue_otp_email).and_return(true)
      UserService.forgetPassword(email: "john.doe@gmail.com")
      allow(UserMailer).to receive(:password_reset_success_email).and_return(double(deliver_later: true))
    end

    let(:valid_reset_params) do
      {
        id: user.id,
        user: {
          new_password: "NewPass@123",
          otp: UserService.class_variable_get(:@@otp)
        }
      }
    end

    let(:invalid_otp_params) do
      {
        id: user.id,
        user: {
          new_password: "NewPass@123",
          otp: 999999 # Invalid OTP
        }
      }
    end

    let(:invalid_password_params) do
      {
        id: user.id,
        user: {
          new_password: "weak", # Invalid password
          otp: UserService.class_variable_get(:@@otp)
        }
      }
    end

    context "with valid user ID, OTP, and new password" do
      it "resets the password successfully" do
        post :resetPassword, params: valid_reset_params
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["message"]).to eq("Password successfully reset")
        expect(user.reload.authenticate("NewPass@123")).to be_truthy
      end
    end

    context "with an invalid user ID" do
      let(:invalid_user_params) do
        {
          id: 999, # Non-existent user ID
          user: {
            new_password: "NewPass@123",
            otp: UserService.class_variable_get(:@@otp)
          }
        }
      end

      it "returns an error response" do
        post :resetPassword, params: invalid_user_params
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to eq("User not found")
      end
    end

    context "with an invalid OTP" do
      it "returns an error response" do
        post :resetPassword, params: invalid_otp_params
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to eq("Invalid or expired OTP")
      end
    end

    context "with an expired OTP" do
      it "returns an error response" do
        Timecop.travel(3.minutes.from_now) do
          post :resetPassword, params: valid_reset_params
          expect(response).to have_http_status(:unprocessable_entity)
          json_response = JSON.parse(response.body)
          expect(json_response["success"]).to be false
          expect(json_response["errors"]).to eq("Invalid or expired OTP")
        end
      end
    end

    context "with an invalid new password" do
      it "returns an error response" do
        post :resetPassword, params: invalid_password_params
        expect(response).to have_http_status(:unprocessable_entity)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be false
        expect(json_response["errors"]).to include("Password must be at least 8 characters long, include one uppercase letter, one lowercase letter, one digit, and one special character")
      end
    end
  end
end