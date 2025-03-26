class Order < ApplicationRecord
  belongs_to :user
  belongs_to :book
  belongs_to :address

  # Validations
  validates :quantity, presence: true,
                      numericality: { only_integer: true, greater_than: 0 },
                      comparison: { less_than_or_equal_to: :available_book_quantity,
                                  message: "cannot exceed available book quantity" }
  validates :price_at_purchase, presence: true,
                               numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true,
                         numericality: { greater_than_or_equal_to: 0 },
                         comparison: { equal_to: :calculated_total,
                                     message: "must match quantity * price_at_purchase" }
  validates :status, presence: true,
                    inclusion: { in: %w[pending processing shipped delivered cancelled],
                               message: "must be a valid status" }

  # Custom method to check available book quantity
  def available_book_quantity
    book&.quantity || 0
  end

  # Custom method to calculate expected total
  def calculated_total
    (quantity || 0) * (price_at_purchase || 0)
  end
end
