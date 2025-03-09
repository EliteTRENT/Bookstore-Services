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
    wishlists = user.wishlists
    if wishlists
      { success: true, wishlists: wishlists }
    else
      { success: false, error: "Wishlist is EMPTY" }
    end
  end
end
