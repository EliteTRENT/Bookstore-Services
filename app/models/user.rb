# app/models/user.rb
class User < ApplicationRecord
  has_many :wishlists
  has_many :wishlist_books, through: :wishlists, source: :book
  has_many :addresses, dependent: :destroy
  has_secure_password
  validates :name, presence: true, format: { with: /\A[A-Z][a-zA-Z]{2,}(?: [A-Z][a-zA-Z]{2,})*\z/, message: "must start with a capital letter, be at least 3 characters long, and contain only alphabets with spaces allowed between words" }
  validates :email, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9._%+-]+@(gmail|yahoo|ask)\.[a-zA-Z]{2,}\z/, message: "must be a valid email with @gmail, @yahoo, or @ask and a valid domain (.com, .in, etc.)" }, unless: :social_login?
  validates :password, presence: true, format: { with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])[A-Za-z\d@$!%*#?&]{8,}\z/, message: "must be at least 8 characters long, include one uppercase letter, one lowercase letter, one digit, and one special character" }, unless: :skip_validation_or_social_login?
  validates :mobile_number, presence: true, uniqueness: true, format: { with: /\A(\+91)?[6-9]\d{9}\z/, message: "must be a 10-digit number starting with 6-9, optionally prefixed with +91" }, unless: :skip_validation_or_social_login?
  validates :role, inclusion: { in: %w[customer admin] }
  has_many :reviews, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :ordered_books, through: :orders, source: :book

  attr_accessor :skip_validation

  def self.from_google(id_token)
    require "google-id-token"
    validator = GoogleIDToken::Validator.new
    payload = validator.check(id_token, ENV["GOOGLE_CLIENT_ID"])
    google_id = payload["sub"]
    email = payload["email"]
    name = payload["name"]
    user = find_by(google_id: google_id) || find_by(email: email)
    if user
      user.update(google_id: google_id) unless user.google_id
    else
      user = create!(
        google_id: google_id,
        email: email,
        name: name,
        password: SecureRandom.hex(16)
      )
    end
    user
  rescue GoogleIDToken::ValidationError => e
    Rails.logger.error "Google token validation failed: #{e.message}"
    nil
  end

  def self.from_github(github_id, email, name)
    user = find_by(github_id: github_id) || find_by(email: email)
    if user
      user.update(github_id: github_id) unless user.github_id
      Rails.logger.info "Linked GitHub account to existing user: #{user.id}"
    else
      Rails.logger.info "Creating new user with GitHub attributes: #{ { github_id: github_id, email: email, name: name }.inspect }"
      user = create!(
        github_id: github_id,
        email: email || "github_#{github_id}@example.com",
        name: name,
        password: SecureRandom.hex(16),
        role: 'customer'
      )
      Rails.logger.info "New user created with GitHub: #{user.id}"
    end
    user
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "GitHub user creation/update failed: #{e.message}"
    nil
  end

  private

  def skip_validation_or_social_login?
    skip_validation || google_id.present? || github_id.present?
  end

  # Changed from class method to instance method
  def social_login?
    google_id.present? || github_id.present?
  end
end