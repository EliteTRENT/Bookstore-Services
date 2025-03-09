class WishlistService
  def self.addBook(user, book)
    wishlist_item = user.wishlists.new(book: book)
    if wishlist_item.save
      { success: true, message: "Book added to wishlist!" }
    else
      { success: false, error: wishlist_item.errors.full_messages }
    end
  end
end
