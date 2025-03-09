class BookService
  def self.create_book(book_params)
    book = Book.new(book_params)
    if book.save
      { success: true, message: "Book created successfully", book: book }
    else
      { success: false, error: book.errors.full_messages }
    end
  end
end
