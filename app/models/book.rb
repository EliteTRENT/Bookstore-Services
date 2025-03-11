class Book < ApplicationRecord
  has_many :wishlists
  has_many :wishlist_users, through: :wishlists, source: :user
  validates :name, presence: true
  validates :author, presence: true
  validates :mrp, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discounted_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  has_many :reviews, dependent: :destroy

  scope :active, -> { where(is_deleted: false) }  # ✅ Filter active books
  scope :deleted, -> { where(is_deleted: true) }  # ✅ Filter deleted books

  def soft_delete
    update(is_deleted: true)  # ✅ Use is_deleted instead of deleted_at
  end
end
