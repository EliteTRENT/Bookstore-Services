# app/models/user.rb
class User < ApplicationRecord
  has_many :wishlists
  has_many :wishlist_books, through: :wishlists, source: :book
  has_many :addresses, dependent: :destroy
  has_secure_password
  validates :name, presence: true, format: { with: /\A[A-Z][a-zA-Z]{2,}(?: [A-Z][a-zA-Z]{2,})*\z/, message: "must start with a capital letter, be at least 3 characters long, and contain only alphabets with spaces allowed between words" }
  validates :email, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9._%+-]+@(gmail|yahoo|ask)\.[a-zA-Z]{2,}\z/, message: "must be a valid email with @gmail, @yahoo, or @ask and a valid domain (.com, .in, etc.)" }
  validates :password, presence: true, format: { with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*#?&]{8,}\z/, message: "must be at least 8 characters long, include one uppercase letter, one lowercase letter, one digit, and one special character" }, unless: :skip_validation_or_social_login?
  validates :mobile_number, presence: true, uniqueness: true, format: { with: /\A(\+91)?[6-9]\d{9}\z/, message: "must be a 10-digit number starting with 6-9, optionally prefixed with +91" }, unless: :skip_validation_or_social_login?
  has_many :reviews, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :ordered_books, through: :orders, source: :book

  attr_accessor :skip_validation # Temporary attribute to bypass validations

  private

  def skip_validation_or_social_login?
    skip_validation || google_id.present?
  end

  def self.from_google(id_token)
    # Use google-id-token gem or similar to validate token
    require "google-id-token"
    validator = GoogleIDToken::Validator.new
    payload = validator.check(id_token, ENV["GOOGLE_CLIENT_ID"])

    # Extract user info from Google payload
    google_id = payload["sub"] # Unique Google user ID
    email = payload["email"]
    name = payload["name"]

    # Find or create user
    user = find_by(google_id: google_id) || find_by(email: email)
    if user
      user.update(google_id: google_id) unless user.google_id # Link Google ID if not already
    else
      user = create!(
        google_id: google_id,
        email: email,
        name: name,
        password: SecureRandom.hex(16) # Dummy password for OAuth users
      )
    end
    user
  rescue GoogleIDToken::ValidationError => e
    Rails.logger.error "Google token validation failed: #{e.message}"
    nil
  end
end
