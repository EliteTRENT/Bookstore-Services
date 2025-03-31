class WishlistService
  INVALID_USER_ERROR = { success: false, error: "Invalid user" }.freeze

  def self.create(user, wishlist_params)
    return INVALID_USER_ERROR unless user

    book = Book.find_by(id: wishlist_params[:book_id])
    return { success: false, error: "Book not found" } unless book

    wishlist_item = user.wishlists.new(book: book)
    if wishlist_item.save
      { success: true, message: "Book added to wishlist!" }
    else
      { success: false, error: wishlist_item.errors.full_messages }
    end
  end

  def self.index(user)
    return INVALID_USER_ERROR unless user

    wishlists = user.wishlists.where(is_deleted: false).includes(:book)

    # Filter out deleted books and mark those wishlists as deleted
    valid_wishlists = wishlists.reject do |wishlist|
      if wishlist.book.nil?
        wishlist.update(is_deleted: true)
        Rails.logger.info("Marked wishlist item #{wishlist.id} as deleted because book_id #{wishlist.book_id} does not exist or is soft-deleted.")
        true # Exclude this wishlist item
      else
        false # Include it
      end
    end

    { success: true, message: valid_wishlists }
  end

  def self.mark_book_as_deleted(user, wishlist_id)
    return INVALID_USER_ERROR unless user

    wishlist_item = user.wishlists.find_by(id: wishlist_id, is_deleted: false)
    return { success: false, error: "Wishlist item not found" } unless wishlist_item

    wishlist_item.update(is_deleted: true)
    { success: true, message: "Book removed from wishlist!" }
  end

  def self.mark_book_as_deleted_by_book_id(user, book_id)
    return { success: false, error: "Invalid user" } unless user

    wishlist_item = user.wishlists.find_by(book_id: book_id, is_deleted: false)
    return { success: false, error: "Book not found in wishlist" } unless wishlist_item

    wishlist_item.update(is_deleted: true)
    { success: true, message: "Book removed from wishlist!" }
  end
end
