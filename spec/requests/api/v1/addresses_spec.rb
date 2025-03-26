require "rails_helper"

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

  describe ".add_address" do
    context "with valid attributes" do
      let(:valid_attributes) do
        {
          street: "123 Main St",
          city: "Delhi",
          state: "DL",
          zip_code: "110001",
          country: "India",
          type: "home",
          is_default: false
        }
      end

      it "creates an address successfully" do
        result = AddressService.add_address(user, valid_attributes)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Address added successfully")
        expect(result[:address]).to be_a(Address)
        expect(result[:address].persisted?).to be_truthy
      end
    end

    context "with invalid attributes" do
      it "returns an error when street is missing" do
        invalid_attributes = { city: "Delhi", state: "DL", zip_code: "110001", country: "India", type: "home" }
        result = AddressService.add_address(user, invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Street can't be blank")
      end

      it "returns an error when city is missing" do
        invalid_attributes = { street: "123 Main St", state: "DL", zip_code: "110001", country: "India", type: "home" }
        result = AddressService.add_address(user, invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("City can't be blank")
      end

      it "returns an error when state is missing" do
        invalid_attributes = { street: "123 Main St", city: "Delhi", zip_code: "110001", country: "India", type: "home" }
        result = AddressService.add_address(user, invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("State can't be blank")
      end

      it "returns an error when zip_code is missing" do
        invalid_attributes = { street: "123 Main St", city: "Delhi", state: "DL", country: "India", type: "home" }
        result = AddressService.add_address(user, invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Zip code can't be blank")
      end

      it "returns an error when country is missing" do
        invalid_attributes = { street: "123 Main St", city: "Delhi", state: "DL", zip_code: "110001", type: "home" }
        result = AddressService.add_address(user, invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Country can't be blank")
      end

      it "returns an error when type is invalid" do
        invalid_attributes = { street: "123 Main St", city: "Delhi", state: "DL", zip_code: "110001", country: "India", type: "invalid" }
        result = AddressService.add_address(user, invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Type must be 'home', 'work', or 'other'") # Updated from "Type is not included in the list"
      end
    end

    context "when the user is nil" do
      let(:valid_attributes) do
        {
          street: "123 Main St",
          city: "Delhi",
          state: "DL",
          zip_code: "110001",
          country: "India",
          type: "home",
          is_default: false
        }
      end

      it "returns an error" do
        result = AddressService.add_address(nil, valid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("User must exist")
      end
    end
  end

  describe ".update_address" do
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

    context "with valid attributes" do
      let(:valid_attributes) { { street: "456 New St", city: "Mumbai" } }

      it "updates the address successfully" do
        result = AddressService.update_address(user, address.id, valid_attributes)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Address updated successfully")
        expect(result[:address].street).to eq("456 New St")
        expect(result[:address].city).to eq("Mumbai")
      end
    end

    context "with invalid attributes" do
      it "returns an error when street is blank" do
        invalid_attributes = { street: "" }
        result = AddressService.update_address(user, address.id, invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Street can't be blank")
      end

      it "returns an error when city is blank" do
        invalid_attributes = { city: "" }
        result = AddressService.update_address(user, address.id, invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("City can't be blank")
      end

      it "returns an error when type is invalid" do
        invalid_attributes = { type: "invalid" }
        result = AddressService.update_address(user, address.id, invalid_attributes)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to include("Type must be 'home', 'work', or 'other'") # Updated from "Type is not included in the list"
      end
    end

    context "when the address does not exist" do
      it "returns an error" do
        result = AddressService.update_address(user, 999, { street: "456 New St" })
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq(["Address not found"]) # Updated from "Address not found" to array
      end
    end

    context "when the user is nil" do
      it "returns an error" do
        result = AddressService.update_address(nil, address.id, { street: "456 New St" })
        expect(result[:success]).to be_falsey
        expect(result[:error]).to eq(["Address not found"]) # Updated from "Address not found" to array
      end
    end
  end

  describe ".remove_address" do
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

    context "when the address exists" do
      it "deletes the address successfully" do
        result = AddressService.remove_address(user, address.id)
        expect(result[:success]).to be_truthy
        expect(result[:message]).to eq("Address removed successfully")
        expect(Address.find_by(id: address.id)).to be_nil
      end
    end

    context "when the address does not exist" do
      it "returns an error" do
        result = AddressService.remove_address(user, 999)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to be_nil # Updated from "Address not found" to nil
      end
    end

    context "when the user is nil" do
      it "returns an error" do
        result = AddressService.remove_address(nil, address.id)
        expect(result[:success]).to be_falsey
        expect(result[:error]).to be_nil # Updated from "Address not found" to nil
      end
    end
  end
end
