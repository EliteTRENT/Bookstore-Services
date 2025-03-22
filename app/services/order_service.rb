class OrderService
  def self.create_order(token, order_params)
    # Decode the token to find the user
    token_payload = JsonWebToken.decode(token)
    return { success: false, error: "Invalid token" } unless token_payload

    token_email = token_payload.is_a?(Hash) ? token_payload[:email] || token_payload["email"] : token_payload
    return { success: false, error: "Invalid token: email not found" } unless token_email

    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user

    # Find the book
    book = Book.find_by(id: order_params[:book_id])
    return { success: false, error: "Book with ID #{order_params[:book_id]} not found" } unless book

    # Find the address
    address = user.addresses.find_by(id: order_params[:address_id])
    return { success: false, error: "Invalid address" } unless address

    # Validate quantity
    return { success: false, error: "Quantity must be a number" } unless order_params[:quantity].to_s.match?(/\A\d+\z/)
    quantity = order_params[:quantity].to_i
    return { success: false, error: "Invalid quantity: must be greater than 0 and less than or equal to available stock (#{book.quantity})" } if quantity <= 0 || quantity > book.quantity

    # Validate price_at_purchase
    price_at_purchase = order_params[:price_at_purchase].to_f
    return { success: false, error: "Invalid price at purchase" } if price_at_purchase <= 0

    # Validate total price
    total_price = order_params[:total_price].to_f
    return { success: false, error: "Invalid total price: must be greater than 0" } if total_price <= 0

    # Verify total price matches quantity * price_at_purchase
    expected_total = (quantity * price_at_purchase).round(2)
    return { success: false, error: "Total price mismatch: expected #{expected_total}, got #{total_price}" } unless (total_price - expected_total).abs < 0.01

    # Create the order and update the book's quantity in a transaction
    ActiveRecord::Base.transaction do
      order = user.orders.create(
        book_id: book.id,
        address_id: address.id,
        quantity: quantity,
        price_at_purchase: price_at_purchase,
        status: "pending",
        total_price: total_price
      )

      if order.persisted?
        # Update the book's quantity
        book.update!(quantity: book.quantity - quantity)
        { success: true, message: "Order placed successfully", order: order }
      else
        { success: false, error: order.errors.full_messages.join(", ") || "Failed to create order" }
      end
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end


  def self.get_all_orders(token)
    token_full = JsonWebToken.decode(token)
    token_email = token_full["email"]
    return { success: false, error: "Invalid token" } unless token_email

    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user

    orders = user.orders
    return { success: false, error: "No orders found" } if orders.empty?

    { success: true, orders: orders }
  end

  def self.get_order_by_id(token, order_id)
    token_full = JsonWebToken.decode(token)
    token_email = token_full["email"]
    return { success: false, error: "Invalid token" } unless token_email

    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user

    order = user.orders.find_by(id: order_id)
    return { success: false, error: "Order not found" } unless order

    { success: true, order: order }
  end

  def self.update_order_status(token, order_id, status)
    token_full = JsonWebToken.decode(token)
    token_email = token_full["email"]
    return { success: false, error: "Invalid token" } unless token_email

    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user

    order = user.orders.find_by(id: order_id)
    return { success: false, error: "Order not found" } unless order

    if order.update(status: status)
      { success: true, message: "Order status updated successfully", order: order }
    else
      { success: false, error: order.errors.full_messages }
    end
  end
end
