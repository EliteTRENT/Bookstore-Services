class WishlistService
  def self.addBook(token, wishlist_params)
    token_email = JsonWebToken.decode(token)
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

  def self.getAll(token)
    token_email = JsonWebToken.decode(token)
    return { success: false, error: "Invalid token" } unless token_email
    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user
    wishlists = user.wishlists.where(is_deleted: false)
    if wishlists
      { success: true, wishlists: wishlists }
    else
      { success: false, error: "Wishlist is EMPTY" }
    end
  end

  def self.destroy(token, book_id)
    token_email = JsonWebToken.decode(token)
    return { success: false, error: "Invalid token" } unless token_email
    user = User.find_by(email: token_email)
    return { success: false, error: "User not found" } unless user
    wishlist_item = user.wishlists.find_by(book_id: book_id, is_deleted: false)
    if wishlist_item
      wishlist_item.update(is_deleted: true)
      { success: true, message: "Book removed from wishlist!" }
    else
      { success: false, error: "Book not found in wishlist" }
    end
  end
end
