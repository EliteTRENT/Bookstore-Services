class AddressService
  def self.list_addresses(user)
    addresses = user&.addresses || []
    { success: true, addresses: addresses }
  end

  def self.add_address(user, address_params)
    return { success: false, error: ["User must exist"] } unless user

    begin
      address = user.addresses.build(address_params)
      if address.save
        { success: true, message: "Address added successfully", address: address }
      else
        { success: false, error: address.errors.full_messages }
      end
    rescue ArgumentError => e
      { success: false, error: ["Type must be 'home', 'work', or 'other'"] }
    end
  end

  def self.update_address(user, address_id, address_params)
    address = user&.addresses&.find_by(id: address_id)
    if address
      begin
        if address.update(address_params)
          { success: true, message: "Address updated successfully", address: address }
        else
          { success: false, error: address.errors.full_messages }
        end
      rescue ArgumentError => e
        { success: false, error: ["Type must be 'home', 'work', or 'other'"] }
      end
    else
      { success: false, error: ["Address not found"] }
    end
  end

  def self.remove_address(user, address_id)
    address = user&.addresses&.find_by(id: address_id)
    if address
      if address.has_orders?
        { success: false, message: "Cannot delete address because it is linked to existing orders" }
      else
        address.destroy
        { success: true, message: "Address removed successfully" }
      end
    else
      { success: false, message: "Address not found" }
    end
  end
end