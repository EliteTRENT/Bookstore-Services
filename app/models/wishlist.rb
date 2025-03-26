# app/models/wishlist.rb
class Wishlist < ApplicationRecord
  belongs_to :user
  belongs_to :book, -> { where(is_deleted: false) }  # Only include active books
  validates :book_id, presence: true, uniqueness: {
    scope: :user_id,
    conditions: -> { where(is_deleted: false) },
    message: "is already in your wishlist"
  }

  def as_json(options = {})
    super(options.merge(include: :book))
  end
end