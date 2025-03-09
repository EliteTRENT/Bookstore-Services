class Book < ApplicationRecord
  validates :name, presence: true
  validates :author, presence: true
  validates :mrp, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discounted_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
