class Address < ApplicationRecord
  belongs_to :user
  has_many :orders, dependent: :nullify  # If address is deleted, orders will still exist with `address_id = NULL`
  validates :street, :city, :state, :zip_code, :country, presence: true
  validates :type, inclusion: { in: %w[home work other] }

  enum :type, { home: "home", work: "work", other: "other" }, prefix: true

  self.inheritance_column = nil # Disable STI
end
