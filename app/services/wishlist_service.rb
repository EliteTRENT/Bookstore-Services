class WishlistService
  def self.create(token, wishlist_params)
    token_full = JsonWebToken.decode(token)
    token_email = token_full["email"]
    return { success: false, error: "Invalid token" } unless token_email
    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user
    book = Book.find_by(id: wishlist_params[:book_id])
    return { success: false, error: "Book not found" } unless book
    wishlist_item = user.wishlists.new(book: book)
    if wishlist_item.save
      { success: true, message: "Book added to wishlist!" }
    else
      { success: false, error: wishlist_item.errors.full_messages }
    end
  end

  def self.index(token)
    token_full = JsonWebToken.decode(token)
    token_email = token_full["email"]
    return { success: false, error: "Invalid token" } unless token_email
    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user

    # Fetch wishlist items with their associated books
    wishlists = user.wishlists.where(is_deleted: false).includes(:book)

    # Filter out wishlist items where the book is nil (e.g., book is deleted or soft-deleted)
    valid_wishlists = wishlists.select do |wishlist|
      if wishlist.book.nil?
        # Mark the wishlist item as deleted since the book no longer exists or is soft-deleted
        wishlist.update(is_deleted: true)
        Rails.logger.info("Marked wishlist item #{wishlist.id} as deleted because book_id #{wishlist.book_id} does not exist or is soft-deleted.")
        false # Exclude this wishlist item
      else
        true # Include this wishlist item
      end
    end

    # Always return success with the wishlist array, even if empty
    { success: true, message: valid_wishlists }
  end

  def self.mark_book_as_deleted(token, wishlist_id)
    token_full = JsonWebToken.decode(token)
    token_email = token_full["email"]
    return { success: false, error: "Invalid token" } unless token_email
    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user
    wishlist_item = user.wishlists.find_by(id: wishlist_id, is_deleted: false)
    if wishlist_item
      wishlist_item.update(is_deleted: true)
      { success: true, message: "Book removed from wishlist!" }
    else
      { success: false, error: "Wishlist item not found" }
    end
  end
end
