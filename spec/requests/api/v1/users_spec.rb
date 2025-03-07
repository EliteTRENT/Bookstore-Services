require 'rails_helper'

RSpec.describe UserService, type: :service do
  describe ".signup" do
    context "with valid attributes" do
      let(:valid_attributes) do
        {
          name: "John Doe",
          email: "john.doe@gmail.com",
          password: "Password@123",
          mobile_number: "9876543210"
        }
      end

      it "creates a user successfully" do
        result = UserService.signup(valid_attributes)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("User created successfully")
        expect(result[:user]).to be_a(User)
        expect(result[:user].persisted?).to be_truthy
      end
    end

    context "with invalid attributes" do
      it "returns an error when name is missing" do
        invalid_attributes = {
          name: "",
          email: "john.doe@gmail.com",
          password: "Password@123",
          mobile_number: "9876543210"
        }
        result = UserService.signup(invalid_attributes)
        expect(result[:error]).to include("Name can't be blank")
      end

      it "returns an error when name format is invalid" do
        invalid_attributes = {
          name: "jd",
          email: "john.doe@gmail.com",
          password: "Password@123",
          mobile_number: "9876543210"
        }
        result = UserService.signup(invalid_attributes)
        expect(result[:error]).to include("Name must start with a capital letter, be at least 3 characters long, and contain only alphabets with spaces allowed between words")
      end

      it "returns an error when email is missing" do
        invalid_attributes = {
          name: "John Doe",
          email: "",
          password: "Password@123",
          mobile_number: "9876543210"
        }
        result = UserService.signup(invalid_attributes)
        expect(result[:error]).to include("Email can't be blank")
      end

      it "returns an error when email is already taken" do
        User.create!(name: "John Doe", email: "john.doe@gmail.com", password: "Password@123", mobile_number: "9876543210")
        invalid_attributes = {
          name: "John Doe",
          email: "john.doe@gmail.com",
          password: "Password@123",
          mobile_number: "9876543211"
        }
        result = UserService.signup(invalid_attributes)
        expect(result[:error]).to include("Email has already been taken")
      end

      it "returns an error when email format is invalid" do
        invalid_attributes = {
          name: "John Doe",
          email: "john.doe@invalid.com",
          password: "Password@123",
          mobile_number: "9876543210"
        }
        result = UserService.signup(invalid_attributes)
        expect(result[:error]).to include("Email must be a valid email with @gmail, @yahoo, or @ask and a valid domain (.com, .in, etc.)")
      end

      it "returns an error when password is missing" do
        invalid_attributes = {
          name: "John Doe",
          email: "john.doe@gmail.com",
          password: "",
          mobile_number: "9876543210"
        }
        result = UserService.signup(invalid_attributes)
        expect(result[:error]).to include("Password can't be blank")
      end

      it "returns an error when password is weak" do
        invalid_attributes = {
          name: "John Doe",
          email: "john.doe@gmail.com",
          password: "weakpass",
          mobile_number: "9876543210"
        }
        result = UserService.signup(invalid_attributes)
        expect(result[:error]).to include("Password must be at least 8 characters long, include one uppercase letter, one lowercase letter, one digit, and one special character")
      end

      it "returns an error when mobile number is missing" do
        invalid_attributes = {
          name: "John Doe",
          email: "john.doe@gmail.com",
          password: "Password@123",
          mobile_number: ""
        }
        result = UserService.signup(invalid_attributes)
        expect(result[:error]).to include("Mobile number can't be blank")
      end

      it "returns an error when mobile number is invalid" do
        invalid_attributes = {
          name: "John Doe",
          email: "john.doe@gmail.com",
          password: "Password@123",
          mobile_number: "12345"
        }
        result = UserService.signup(invalid_attributes)
        expect(result[:error]).to include("Mobile number must be a 10-digit number starting with 6-9, optionally prefixed with +91")
      end

      it "returns an error when mobile number is already taken" do
        User.create!(name: "John Doe", email: "john.doe@gmail.com", password: "Password@123", mobile_number: "9876543210")
        invalid_attributes = {
          name: "Jane Doe",
          email: "jane.doe@gmail.com",
          password: "Password@123",
          mobile_number: "9876543210"
        }
        result = UserService.signup(invalid_attributes)
        expect(result[:error]).to include("Mobile number has already been taken")
      end
    end
  end

  describe ".login" do
    let!(:user) do
      User.create!(
        name: "John Doe",
        email: "john.doe@gmail.com",
        password: "Password@123",
        mobile_number: "9876543210"
      )
    end

    context "with valid credentials" do
      it "logs in successfully and returns a token" do
        result = UserService.login(email: "john.doe@gmail.com", password: "Password@123")
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Login successful")
        expect(result[:token]).not_to be_nil
      end
    end

    context "with incorrect password" do
      it "returns an error" do
        result = UserService.login(email: "john.doe@gmail.com", password: "WrongPass123")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Wrong password")
      end
    end

    context "with unregistered email" do
      it "returns an error" do
        result = UserService.login(email: "unknown@gmail.com", password: "Password@123")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Email is not registered")
      end
    end

    context "with missing email" do
      it "returns an error" do
        result = UserService.login(email: "", password: "Password@123")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Email is not registered")
      end
    end

    context "with missing password" do
      it "returns an error" do
        result = UserService.login(email: "john.doe@gmail.com", password: "")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Wrong password")
      end
    end

    context "with invalid email format" do
      it "returns an error" do
        result = UserService.login(email: "john.doe#gmail.com", password: "Password@123")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Email is not registered")
      end
    end

    context "with invalid password format" do
      it "returns an error" do
        result = UserService.login(email: "john.doe@gmail.com", password: "pass")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Wrong password")
      end
    end

    context "with different email providers" do
      let!(:user_yahoo) do
        User.create!(name: "Jane Doe", email: "jane.doe@yahoo.com", password: "Password@123", mobile_number: "9876543211")
      end

      it "logs in successfully with Yahoo email" do
        result = UserService.login(email: "jane.doe@yahoo.com", password: "Password@123")
        expect(result[:success]).to be_truthy
      end
    end
  end

  describe ".forgetPassword" do
    let!(:user) do
      User.create!(
        name: "John Doe",
        email: "john.doe@gmail.com",
        password: "Password@123",
        mobile_number: "9876543210"
      )
    end

    context "with a registered email" do
      before do
        allow(UserMailer).to receive(:enqueue_otp_email).and_return(true)
      end

      it "initiates password reset successfully" do
        result = UserService.forgetPassword(email: "john.doe@gmail.com")
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("OTP has been sent to john.doe@gmail.com, check your inbox")
        expect(result[:otp]).to be_a(Integer)
        expect(result[:otp]).to be_between(100000, 999999)
        expect(result[:user_id]).to eq(user.id)
        expect(UserMailer).to have_received(:enqueue_otp_email).with(user, result[:otp])
      end
    end

    context "with an unregistered email" do
      it "returns an error" do
        result = UserService.forgetPassword(email: "unknown@gmail.com")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Email is not registered")
      end
    end

    context "with an empty email" do
      it "returns an error" do
        result = UserService.forgetPassword(email: "")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Email is not registered")
      end
    end

    context "when RabbitMQ enqueue fails" do
      before do
        allow(UserMailer).to receive(:enqueue_otp_email).and_raise(StandardError, "RabbitMQ connection failed")
      end

      it "returns an error" do
        result = UserService.forgetPassword(email: "john.doe@gmail.com")
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Failed to send OTP, please try again")
      end
    end
  end
  describe ".resetPassword" do
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

    context "with a valid user ID and OTP" do
      it "resets the password successfully" do
        result = UserService.resetPassword(user.id, new_password: "NewPass@123", otp: UserService.class_variable_get(:@@otp))
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Password successfully reset")
        expect(user.reload.authenticate("NewPass@123")).to be_truthy
        expect(UserMailer).to have_received(:password_reset_success_email).with(user)
      end
    end

    context "with an invalid user ID" do
      it "returns an error" do
        result = UserService.resetPassword(999, new_password: "NewPass@123", otp: UserService.class_variable_get(:@@otp))
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("User not found")
      end
    end

    context "with an invalid OTP" do
      it "returns an error" do
        result = UserService.resetPassword(user.id, new_password: "NewPass@123", otp: 999999)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq("Invalid or expired OTP")
      end
    end

    context "with an expired OTP" do
      it "returns an error" do
        Timecop.travel(3.minutes.from_now) do
          result = UserService.resetPassword(user.id, new_password: "NewPass@123", otp: UserService.class_variable_get(:@@otp))
          expect(result[:success]).to be_falsey
          expect(result[:error]).to eq("Invalid or expired OTP")
        end
      end
    end

    context "with an invalid new password" do
      it "returns an error" do
        result = UserService.resetPassword(user.id, new_password: "weak", otp: UserService.class_variable_get(:@@otp))
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Password must be at least 8 characters long, include one uppercase letter, one lowercase letter, one digit, and one special character")
      end
    end
  end
end
