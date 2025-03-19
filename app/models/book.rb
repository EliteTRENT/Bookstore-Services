class Book < ApplicationRecord
  has_many :wishlists
  has_many :wishlist_users, through: :wishlists, source: :user
  has_many :reviews, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :ordered_users, through: :orders, source: :user

  validates :name, presence: true
  validates :author, presence: true
  validates :mrp, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discounted_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(is_deleted: false) }  # Filter active books
  scope :deleted, -> { where(is_deleted: true) }  # Filter deleted books

  def soft_delete
    update(is_deleted: true)  # Use is_deleted instead of deleted_at
  end

  # Calculate the average rating for the book
  def average_rating
    reviews_count = reviews.count
    reviews_count > 0 ? (reviews.sum(:rating).to_f / reviews_count).round(1) : 0
  end

  # Get the total number of reviews for the book
  def total_reviews
    reviews.count
  end
end
