class CartService
  def self.add_book(cart_params)
    return { success: false, error: "Invalid quantity" } if cart_params[:quantity].nil? || cart_params[:quantity].to_i <= 0

    cart_item = Cart.find_by(user_id: cart_params[:user_id], book_id: cart_params[:book_id], is_deleted: false)

    if cart_item
      cart_item.quantity += cart_params[:quantity].to_i
      if cart_item.save
        { success: true, message: "Book quantity updated in cart", cart: cart_item }
      else
        { success: false, error: cart_item.errors.full_messages }
      end
    else
      cart_item = Cart.new(cart_params)
      if cart_item.save
        { success: true, message: "Book added to cart", cart: cart_item }
      else
        { success: false, error: cart_item.errors.full_messages }
      end
    end
  end

  def self.get_cart(user_id)
    cart_items = Cart.where(user_id: user_id, is_deleted: false).includes(:book)
    if cart_items.any?
      cart_data = cart_items.map do |item|
        {
          cart_id: item.id,
          book_id: item.book_id,
          book_name: item.book&.name,
          quantity: item.quantity,
          price: item.book&.discounted_price
        }
      end
      { success: true, message: "Cart retrieved successfully", cart: cart_data }
    else
      { success: true, message: "Cart is empty", cart: [] }
    end
  rescue StandardError => e
    { success: false, error: "Error retrieving cart: #{e.message}" }
  end

  # ✅ Soft delete a book (updates `deleted_at` column)
  def self.soft_delete_book(book_id, user_id)
    cart_item = Cart.find_by(book_id: book_id, user_id: user_id, is_deleted: false)
    return { success: false, error: "Cart item not found" } unless cart_item

    if cart_item.quantity > 1
      # Decrease quantity by 1
      cart_item.quantity -= 1
      if cart_item.save
        { success: true, message: "Book quantity decreased in cart", book: cart_item }
      else
        { success: false, error: cart_item.errors.full_messages }
      end
    else
      # Quantity is 1, so soft-delete the cart item
      if cart_item.update(is_deleted: true)
        { success: true, message: "Book removed from cart", book: cart_item }
      else
        { success: false, error: cart_item.errors.full_messages }
      end
    end
  rescue StandardError => e
    { success: false, error: "Error updating cart item: #{e.message}" }
  end
end
