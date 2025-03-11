class Wishlist < ApplicationRecord
  belongs_to :user
  belongs_to :book
  validates :book_id, presence: true, uniqueness: {
    scope: :user_id,
    conditions: -> { where(is_deleted: false) },
    message: "is already in your wishlist"
  }
end
