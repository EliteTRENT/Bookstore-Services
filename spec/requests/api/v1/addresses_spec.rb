require 'rails_helper'

RSpec.describe AddressService, type: :service do
  let!(:user) { User.create!(name: "John Doe", email: "john.doe@gmail.com", password: "Password@123", mobile_number: "9876543210") }

  describe ".list_addresses" do
    context "when the user has addresses" do
      let!(:address) do
        Address.create!(
          user: user,
          street: "123 Main St",
          city: "Delhi",
          state: "DL",
          zip_code: "110001",
          country: "India",
          type: "home",
          is_default: false
        )
      end

      it "returns a list of the user's addresses" do
        result = AddressService.list_addresses(user)
        expect(result[:success]).to be_truthy
        expect(result[:addresses]).to include(address)
        expect(result[:addresses].count).to eq(1)
      end
    end

    context "when the user has no addresses" do
      it "returns an empty list" do
        result = AddressService.list_addresses(user)
        expect(result[:success]).to be_truthy
        expect(result[:addresses]).to be_empty
      end
    end

    context "when the user is nil" do
      it "returns an empty list" do
        result = AddressService.list_addresses(nil)
        expect(result[:success]).to be_truthy
        expect(result[:addresses]).to be_empty
      end
    end
  end
end
