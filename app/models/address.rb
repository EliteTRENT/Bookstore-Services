# app/models/address.rb
class Address < ApplicationRecord
  belongs_to :user
  has_many :orders, dependent: :nullify
  validates :street, presence: true, length: { minimum: 5, maximum: 100 }
  validates :city, presence: true, length: { minimum: 2, maximum: 50 }, format: { with: /\A[a-zA-Z\s-]+\z/, message: "must contain only letters, spaces, or hyphens" }
  validates :state, presence: true, length: { minimum: 2, maximum: 50 }, format: { with: /\A[a-zA-Z\s]+\z/, message: "must contain only letters and spaces (no numbers)" }
  validates :zip_code, presence: true, length: { minimum: 3, maximum: 10 }, format: { with: /\A[a-zA-Z0-9\s-]+\z/, message: "must be 3-10 characters including letters, numbers, spaces, or hyphens" }
  validates :country, presence: true, length: { minimum: 2, maximum: 50 }, format: { with: /\A[a-zA-Z\s]+\z/, message: "must contain only letters and spaces (no numbers)" }
  validates :type, inclusion: { in: %w[home work other], message: "must be 'home', 'work', or 'other'" }

  enum :type, { home: "home", work: "work", other: "other" }, prefix: true

  self.inheritance_column = nil # Disable STI

  # Check if the address is linked to any orders
  def has_orders?
    orders.any?
  end
end