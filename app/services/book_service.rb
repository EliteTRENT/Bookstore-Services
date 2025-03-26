class BookService
  require "csv"  # Required for CSV parsing

  def self.create_book(book_params)
    if book_params[:file].present?
      create_books_from_csv(book_params[:file])
    else
      book = Book.new(book_params.except(:file))
      if book.save
        REDIS.keys("books:all:*").each { |key| REDIS.del(key) }
        { success: true, message: "Book created successfully", book: book }
      else
        { success: false, error: book.errors.full_messages }
      end
    end
  end

  def self.create_books_from_csv(file)
    csv = CSV.read(file.path, headers: true)
    books = []

    csv.each do |row|
      book = Book.new(
        name: row["book_name"],
        author: row["author_name"],
        mrp: row["book_mrp"],
        discounted_price: row["discounted_price"],
        quantity: row["quantity"],
        book_details: row["book_details"],
        genre: row["genre"],
        book_image: row["book_image"],
        is_deleted: row["is_deleted"] == "true" # Convert string "true"/"false" to boolean
      )

      books << book if book.save
    end

    if books.any?
      REDIS.keys("books:all:*").each { |key| REDIS.del(key) }
      { success: true, message: "Books created successfully from CSV", books: books }
    else
      { success: false, error: "Failed to create books from CSV" }
    end
  end

  def self.update_book(book_id, book_params)
    book = Book.find_by(id: book_id, is_deleted: false)
    return { success: false, error: "Book not found or has been deleted" } if book.nil?

    if book.update(book_params)
      REDIS.keys("books:all:*").each { |key| REDIS.del(key) }
      REDIS.del("book:#{book_id}")
      { success: true, message: "Book updated successfully", book: book }
    else
      { success: false, error: book.errors.full_messages }
    end
  end

  def self.index_books(page = 1, per_page = 10, sort_by = nil)
    cache_key = "books:all:#{page}:#{per_page}:#{sort_by || 'default'}"
    cached_result = REDIS.get(cache_key)
    if cached_result
      return JSON.parse(cached_result, symbolize_names: true)
    end

    books_query = Book.active

    case sort_by
    when "price-low"
      books_query = books_query.order(discounted_price: :asc, created_at: :desc)
    when "price-high"
      books_query = books_query.order(discounted_price: :desc, created_at: :desc)
    else
      books_query = books_query.order(created_at: :desc)
    end

    books = books_query.page(page).per(per_page)
    total_count = Book.active.count
    total_pages = (total_count.to_f / per_page).ceil

    books_with_reviews = books.map do |book|
      book.as_json.merge(
        average_rating: book.average_rating,
        total_reviews: book.total_reviews
      )
    end

    result = if books.any?
               {
                 success: true,
                 message: "Books retrieved successfully",
                 books: books_with_reviews,
                 pagination: {
                   current_page: page.to_i,
                   per_page: per_page,
                   total_pages: total_pages,
                   total_count: total_count
                 }
               }
    else
               {
                 success: true,
                 message: "No books available",
                 books: [],
                 pagination: {
                   current_page: page.to_i,
                   per_page: per_page,
                   total_pages: total_pages,
                   total_count: total_count
                 }
               }
    end

    REDIS.setex(cache_key, 3600, result.to_json)
    result
  rescue StandardError => e
    { success: false, error: "Internal server error occurred while retrieving books: #{e.message}" }
  end

  def self.get_book_by_id(book_id)
    cache_key = "book:#{book_id}"
    cached_result = REDIS.get(cache_key)
    if cached_result
      return JSON.parse(cached_result, symbolize_names: true)
    end

    book = Book.find_by(id: book_id, is_deleted: false)
    result = if book
               book_data = book.as_json.merge(
                 average_rating: book.average_rating,
                 total_reviews: book.total_reviews
               )
               { success: true, message: "Book retrieved successfully", book: book_data }
    else
               { success: false, error: "Book not found or has been deleted" }
    end

    REDIS.setex(cache_key, 3600, result.to_json) if result[:success]
    result
  end

  def self.toggle_delete(book_id)
    book = Book.find_by(id: book_id)
    if !book
      return { success: false, error: "Book not found" }
    end
    new_status = !book.is_deleted
    if book.update(is_deleted: new_status)
      REDIS.keys("books:all:*").each { |key| REDIS.del(key) }
      REDIS.del("book:#{book_id}")
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
      REDIS.keys("books:all:*").each { |key| REDIS.del(key) }
      REDIS.del("book:#{book_id}")
      { success: true, message: "Book permanently deleted" }
    else
      { success: false, error: book.errors.full_messages }
    end
  end

  def self.search_suggestions(query)
    return { success: false, error: "Query parameter is required" } if query.blank?

    cache_key = "books:search:#{query.downcase}"
    cached_result = REDIS.get(cache_key)
    if cached_result
      return JSON.parse(cached_result, symbolize_names: true)
    end

    books = Book.active
                .where("name ILIKE ? OR author ILIKE ? OR genre ILIKE ?",
                       "%#{query}%", "%#{query}%", "%#{query}%")
                .limit(10)

    suggestions = books.map do |book|
      book.as_json.merge(
        average_rating: book.average_rating,
        total_reviews: book.total_reviews
      )
    end

    result = {
      success: true,
      message: "Search suggestions retrieved successfully",
      suggestions: suggestions
    }

    REDIS.setex(cache_key, 1800, result.to_json)
    result
  rescue StandardError => e
    { success: false, error: "Error retrieving suggestions: #{e.message}" }
  end

  def self.fetch_stock(book_ids)
    # Validate input: Ensure book_ids is an array of positive integers
    unless book_ids.is_a?(Array) && book_ids.all? { |id| id.is_a?(Integer) && id > 0 }
      return { success: false, error: "Invalid book_ids: must be an array of positive integers" }
    end

    begin
      # Fetch books with the given IDs, selecting only the id and quantity columns
      books = Book.where(id: book_ids).select(:id, :quantity)

      # If no books are found, return an error
      if books.empty?
        return { success: false, error: "No books found for the given IDs" }
      end

      # Check if all requested book IDs were found
      found_book_ids = books.map(&:id)
      missing_book_ids = book_ids - found_book_ids
      unless missing_book_ids.empty?
        return { success: false, error: "Books not found: #{missing_book_ids.join(', ')}" }
      end

      # Map the books to the required format: [{ book_id: ..., quantity: ... }, ...]
      stock_data = books.map do |book|
        {
          book_id: book.id,
          quantity: book.quantity
        }
      end

      # Return success response with stock data
      { success: true, stock: stock_data }
    rescue StandardError => e
      # Log the error and return a failure response
      Rails.logger.error("Error fetching stock for book_ids #{book_ids}: #{e.message}")
      { success: false, error: "Failed to fetch stock quantities: #{e.message}" }
    end
  end
end
