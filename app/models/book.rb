class Book < ApplicationRecord
  has_many :wishlists
  has_many :wishlist_users, through: :wishlists, source: :user
end
