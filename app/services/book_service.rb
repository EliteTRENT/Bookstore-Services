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

  def self.get_all_books(page = 1, per_page = 10, sort_by = nil)
    # Generate a unique cache key based on page, per_page, and sort_by
    cache_key = "books:all:#{page}:#{per_page}:#{sort_by || 'default'}"

    # Try to fetch from cache
    cached_result = REDIS.get(cache_key)
    if cached_result
      return JSON.parse(cached_result, symbolize_names: true)
    end

    # Fetch books with sorting
    books_query = Book.active

    # Apply sorting based on sort_by parameter
    case sort_by
    when 'price-low'
      books_query = books_query.order(discounted_price: :asc, created_at: :desc)
    when 'price-high'
      books_query = books_query.order(discounted_price: :desc, created_at: :desc)
    else
      # Default sorting by created_at (relevance)
      books_query = books_query.order(created_at: :desc)
    end

    # Apply pagination
    books = books_query.page(page).per(per_page)

    total_count = Book.active.count
    total_pages = (total_count.to_f / per_page).ceil

    # Include average_rating and total_reviews in the response
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
               book_data = book.as_json.merge(
                 average_rating: book.average_rating,
                 total_reviews: book.total_reviews
               )
               { success: true, message: "Book retrieved successfully", book: book_data }
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
    books = Book.active
                .where("name ILIKE ? OR author ILIKE ? OR genre ILIKE ?",
                       "%#{query}%", "%#{query}%", "%#{query}%")
                .limit(10)

    # Include average_rating and total_reviews in the response
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

    # Cache for 30 minutes
    REDIS.setex(cache_key, 1800, result.to_json)

    result
  rescue StandardError => e
    { success: false, error: "Error retrieving suggestions: #{e.message}" }
  end
end
