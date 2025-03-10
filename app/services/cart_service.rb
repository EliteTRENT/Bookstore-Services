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
end
