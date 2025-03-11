class Book < ApplicationRecord
  has_many :wishlists
  has_many :wishlist_users, through: :wishlists, source: :user
  validates :name, presence: true
  validates :author, presence: true
  validates :mrp, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discounted_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  has_many :reviews, dependent: :destroy

  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def soft_delete
    update(deleted_at: Time.current)
  end
end
