# app/models/address.rb
class Address < ApplicationRecord
  belongs_to :user
  has_many :orders, dependent: :nullify  # No change here
  validates :street, :city, :state, :zip_code, :country, presence: true
  validates :type, inclusion: { in: %w[home work other] }

  enum :type, { home: "home", work: "work", other: "other" }, prefix: true

  self.inheritance_column = nil # Disable STI

  # Check if the address is linked to any orders
  def has_orders?
    orders.any?
  end
end