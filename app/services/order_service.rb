class OrderService
  def self.create_order(token, order_params)
    token_email = JsonWebToken.decode(token)
    return { success: false, error: "Invalid token" } unless token_email

    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user

    book = Book.find_by(id: order_params[:book_id])
    return { success: false, error: "Book not found" } unless book

    address = user.addresses.find_by(id: order_params[:address_id])
    return { success: false, error: "Invalid address" } unless address

    quantity = order_params[:quantity].to_i
    return { success: false, error: "Invalid quantity" } if quantity <= 0 || quantity > book.quantity

    total_price = quantity * book.discounted_price
    order = user.orders.create(
      book_id: book.id,
      address_id: address.id,
      quantity: quantity,
      price_at_purchase: book.discounted_price,
      status: "pending",
      total_price: total_price
    )

    if order.persisted?
      book.update(quantity: book.quantity - quantity)
      { success: true, message: "Order placed successfully", order: order }
    else
      { success: false, error: order.errors.full_messages }
    end
  end

  def self.get_all_orders(token)
    token_email = JsonWebToken.decode(token)
    return { success: false, error: "Invalid token" } unless token_email

    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user

    orders = user.orders
    return { success: false, error: "No orders found" } if orders.empty?

    { success: true, orders: orders }
  end

  def self.get_order_by_id(token, order_id)
    token_email = JsonWebToken.decode(token)
    return { success: false, error: "Invalid token" } unless token_email

    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user

    order = user.orders.find_by(id: order_id)
    return { success: false, error: "Order not found" } unless order

    { success: true, order: order }
  end
end
