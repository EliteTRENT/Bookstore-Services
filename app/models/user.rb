class User < ApplicationRecord
  has_secure_password
  validates :name, presence: true, format: { with: /\A[A-Z][a-zA-Z]{2,}(?: [A-Z][a-zA-Z]{2,})*\z/, message: "must start with a capital letter, be at least 3 characters long, and contain only alphabets with spaces allowed between words" }
  validates :email, presence: true, uniqueness: true, format: { with: /\A[a-zA-Z0-9._%+-]+@(gmail|yahoo|ask)\.[a-zA-Z]{2,}\z/, message: "must be a valid email with @gmail, @yahoo, or @ask and a valid domain (.com, .in, etc.)" }
  validates :password, presence: true, format: { with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}\z/, message: "must be at least 8 characters long, include one uppercase letter, one lowercase letter, one digit, and one special character" }
  validates :mobile_number, presence: true, uniqueness: true, format: { with: /\A(\+91)?[6-9]\d{9}\z/, message: "must be a 10-digit number starting with 6-9, optionally prefixed with +91" }
end
