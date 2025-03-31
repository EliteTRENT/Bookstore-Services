class OrderService
  INVALID_TOKEN_ERROR = "Invalid token".freeze
  def self.update_order_status(token, order_id, status)
    token_full = JsonWebToken.decode(token)
    token_email = token_full["email"]

    user_result = validate_user(token_email)
    return user_result unless user_result[:success]

    order_result = validate_order_for_update(user_result[:user], order_id, status)
    return order_result unless order_result[:success]

    update_order_and_book(order_result[:order], status)
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.record.errors.full_messages }
  rescue StandardError => e
    { success: false, error: "An unexpected error occurred: #{e.message}" }
  end

  def self.create_order(token, order_params)
    token_payload = JsonWebToken.decode(token)
    return { success: false, error: INVALID_TOKEN_ERROR } unless token_payload

    token_email = token_payload.is_a?(Hash) ? token_payload[:email] || token_payload["email"] : token_payload
    user_result = validate_user(token_email)
    return user_result unless user_result[:success]

    validation_result = validate_order_params(user_result[:user], order_params)
    return validation_result unless validation_result[:success]

    process_order_creation(user_result[:user], validation_result[:data])
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def self.index_orders(token)
    token_full = JsonWebToken.decode(token)
    token_email = token_full["email"]
    return { success: false, error: INVALID_TOKEN_ERROR } unless token_email

    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user

    orders = user.orders
    return { success: false, error: "No orders found" } if orders.empty?

    { success: true, orders: orders }
  end

  def self.get_order_by_id(token, order_id)
    token_full = JsonWebToken.decode(token)
    token_email = token_full["email"]
    return { success: false, error: INVALID_TOKEN_ERROR } unless token_email

    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user

    order = user.orders.find_by(id: order_id)
    return { success: false, error: "Order not found" } unless order
    return { success: false, error: "Only pending orders can be cancelled" } unless order.status == "pending"

    { success: true, order: order }
  end

  private

  def self.validate_user(token_email)
    return { success: false, error: "Invalid token: email not found" } unless token_email
    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user
    { success: true, user: user }
  end

  def self.validate_order_for_update(user, order_id, status)
    order = user.orders.find_by(id: order_id)
    return { success: false, error: "Order not found" } unless order
    return { success: false, error: "Only pending orders can be cancelled" } unless order.status == "pending"
    { success: true, order: order }
  end

  def self.update_order_and_book(order, status)
    ActiveRecord::Base.transaction do
      order.update_columns(status: status)
      if status == "cancelled"
        book = order.book
        return { success: false, error: "Associated book not found" } unless book
        book.update!(quantity: book.quantity + order.quantity)
      end
      { success: true, message: "Order status updated successfully", order: order }
    end
  rescue ActiveRecord::RecordInvalid => e
    { success: false, error: e.record.errors.full_messages }
  rescue StandardError => e
    { success: false, error: "An unexpected error occurred: #{e.message}" }
  end

  def self.create_order(user_id, order_params)
    user = User.find_by(id: user_id)
    return { success: false, error: "User not found" } unless user

  end

  def self.validate_order_params(user, order_params)
    book = Book.find_by(id: order_params[:book_id])
    return { success: false, error: "Book with ID #{order_params[:book_id]} not found" } unless book

    address = user.addresses.find_by(id: order_params[:address_id])
    return { success: false, error: "Invalid address" } unless address

    quantity = order_params[:quantity].to_i
    return { success: false, error: "Invalid quantity: must be greater than 0 and less than or equal to available stock (#{book.quantity})" } if quantity <= 0 || quantity > book.quantity

    price_at_purchase = order_params[:price_at_purchase].to_f
    return { success: false, error: "Invalid price at purchase" } if price_at_purchase <= 0

    total_price = order_params[:total_price].to_f
    return { success: false, error: "Invalid total price: must be greater than 0" } if total_price <= 0

    expected_total = (quantity * price_at_purchase).round(2)
    return { success: false, error: "Total price mismatch: expected #{expected_total}, got #{total_price}" } unless (total_price - expected_total).abs < 0.01

    { success: true, data: { book: book, address: address, quantity: quantity, price_at_purchase: price_at_purchase, total_price: total_price } }
  end

  def self.process_order_creation(user, order_data)
    ActiveRecord::Base.transaction do
      order = user.orders.create(
        book_id: order_data[:book].id,
        address_id: order_data[:address].id,
        quantity: order_data[:quantity],
        price_at_purchase: order_data[:price_at_purchase],
        status: "pending",
        total_price: order_data[:total_price]
      )

      if order.persisted?
        order_data[:book].update!(quantity: order_data[:book].quantity - order_data[:quantity])
        begin
          UserMailer.enqueue_order_confirmation_email(order)
        rescue StandardError => e
          Rails.logger.error "Failed to enqueue order confirmation email: #{e.message}"
        end
        { success: true, message: "Order placed successfully", order: order }
      else
        { success: false, error: order.errors.full_messages.join(", ") || "Failed to create order" }
      end
    end
  end

  def self.index_orders(user_id)
    user = User.find_by(id: user_id)
    return { success: false, error: "User not found" } unless user

    orders = user.orders
    return { success: false, error: "No orders found" } if orders.empty?

    { success: true, orders: orders }
  end

  def self.get_order_by_id(user_id, order_id)
    user = User.find_by(id: user_id)
    return { success: false, error: "User not found" } unless user

    order = user.orders.find_by(id: order_id)
    return { success: false, error: "Order not found" } unless order

    { success: true, order: order }
  end
end
