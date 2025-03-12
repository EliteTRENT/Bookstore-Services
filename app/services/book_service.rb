class BookService
  def self.create_book(book_params)
    book = Book.new(book_params)
    if book.save
      # Invalidate cache for get_all_books since a new book is added
      REDIS.keys("books:all:*").each { |key| REDIS.del(key) }
      { success: true, message: "Book created successfully", book: book }
    else
      { success: false, error: book.errors.full_messages }
    end
  end

  def self.update_book(book_id, book_params)
    book = Book.find_by(id: book_id, is_deleted: false)
    return { success: false, error: "Book not found or has been deleted" } if book.nil?

    if book.update(book_params)
      # Invalidate cache for get_all_books and specific book
      REDIS.keys("books:all:*").each { |key| REDIS.del(key) }
      REDIS.del("book:#{book_id}")
      { success: true, message: "Book updated successfully", book: book }
    else
      { success: false, error: book.errors.full_messages }
    end
  end

  def self.get_all_books(page = 1, per_page = 10)
    # Generate a unique cache key based on page and per_page
    cache_key = "books:all:#{page}:#{per_page}"

    # Try to fetch from cache
    cached_result = REDIS.get(cache_key)
    if cached_result
      return JSON.parse(cached_result, symbolize_names: true)
    end

    # Fetch from database if cache miss
    books = Book.where(is_deleted: false)
                .order(created_at: :desc)
                .page(page)
                .per(per_page)

    total_count = Book.where(is_deleted: false).count
    total_pages = (total_count.to_f / per_page).ceil

    result = if books.any?
               {
                 success: true,
                 message: "Books retrieved successfully",
                 books: books.as_json, # Serialize to JSON-friendly format
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

    # Store in Redis with 1-hour expiration
    REDIS.setex(cache_key, 3600, result.to_json)

    result
  rescue StandardError => e
    { success: false, error: "Internal server error occurred while retrieving books: #{e.message}" }
  end

  def self.get_book_by_id(book_id)
    # Generate a cache key for individual book
    cache_key = "book:#{book_id}"

    # Try to fetch from cache
    cached_result = REDIS.get(cache_key)
    if cached_result
      return JSON.parse(cached_result, symbolize_names: true)
    end

    # Fetch from database if cache miss
    book = Book.find_by(id: book_id, is_deleted: false)
    result = if book
               { success: true, message: "Book retrieved successfully", book: book.as_json }
             else
               { success: false, error: "Book not found or has been deleted" }
             end

    # Cache successful result for 1 hour
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
      # Invalidate caches
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
      # Invalidate caches
      REDIS.keys("books:all:*").each { |key| REDIS.del(key) }
      REDIS.del("book:#{book_id}")
      { success: true, message: "Book permanently deleted" }
    else
      { success: false, error: book.errors.full_messages }
    end
  end

  def self.search_suggestions(query)
    return { success: false, error: "Query parameter is required" } if query.blank?

    # Generate a cache key based on query
    cache_key = "books:search:#{query.downcase}"

    # Try to fetch from cache
    cached_result = REDIS.get(cache_key)
    if cached_result
      return JSON.parse(cached_result, symbolize_names: true)
    end

    # Fetch from database if cache miss
    suggestions = Book.where(is_deleted: false)
                     .where("name ILIKE ? OR author ILIKE ? OR genre ILIKE ?",
                            "%#{query}%", "%#{query}%", "%#{query}%")
                     .limit(10)
                     .pluck(:name, :author, :genre)
                     .map { |name, author, genre| { name: name, author: author, genre: genre } }

    result = {
      success: true,
      message: "Search suggestions retrieved successfully",
      suggestions: suggestions
    }

    # Cache for 30 minutes
    REDIS.setex(cache_key, 1800, result.to_json)

    result
  rescue StandardError => e
    { success: false, error: "Error retrieving suggestions: #{e.message}" }
  end
end
