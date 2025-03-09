class BookService
  def self.create_book(book_params)
    book = Book.new(book_params)
    if book.save
      { success: true, message: "Book created successfully", book: book }
    else
      { success: false, error: book.errors.full_messages }
    end
  end

  def self.update_book(book_id, book_params)
    book = Book.find_by(id: book_id, is_deleted: false)

    return { success: false, error: "Book not found or has been deleted" } if book.nil?

    if book.update(book_params)
      { success: true, message: "Book updated successfully", book: book }
    else
      { success: false, error: book.errors.full_messages }
    end
  end

  def self.get_all_books
    books = Book.where(is_deleted: false).order(created_at: :desc)
    if books.any?
      { success: true, message: "Books retrieved successfully", books: books }
    else
      { success: true, message: "No books available", books: [] }
    end
  rescue StandardError => e
    { success: false, error: "Internal server error occurred while retrieving books: #{e.message}" }
  end

  def self.get_book_by_id(book_id)
    book = Book.find_by(id: book_id, is_deleted: false)
    if book
      { success: true, message: "Book retrieved successfully", book: book }
    else
      { success: false, error: "Book not found or has been deleted" }
    end
  end

  def self.toggle_delete(book_id)
    book = Book.find_by(id: book_id)
    if !book
      return { success: false, error: "Book not found" }
    end
    new_status = !book.is_deleted
    if book.update(is_deleted: new_status)
      message = new_status ? "Book marked as deleted" : "Book restored"
      { success: true, message: message, book: book }
    else
      { success: false, error: book.errors.full_messages }
    end
  end

  def self.hard_delete(book_id)
    book = Book.find_by(id: book_id)
    return { success: false, error: "Book not found" } unless book

    if book.destroy
      { success: true, message: "Book permanently deleted" }
    else
      { success: false, error: book.errors.full_messages }
    end
  end
end
