# app/mailers/user_mailer.rb
require 'json'

class UserMailer < ApplicationMailer
  default from: "aryannegi522@gmail.com"

  def self.enqueue_otp_email(user, otp)
    channel = ::CHANNEL # Explicitly reference the global CHANNEL
    queue = channel.queue("otp_emails")
    queue.publish({ email: user.email, otp: otp }.to_json)
  end

  def self.enqueue_welcome_email(user)
    channel = ::CHANNEL
    queue = channel.queue("welcome_emails")
    message = { email: user.email, user_name: user.name }.to_json
    queue.publish(message, persistent: true)
  end

  def self.enqueue_order_confirmation_email(order)
    channel = ::CHANNEL
    queue = channel.queue("order_confirmations")
    book = order.book
    Rails.logger.info " [x] Book details: #{book.attributes.inspect}"
    message = {
      email: order.user.email,
      order_id: order.id,
      total_price: order.total_price,
      quantity: order.quantity,
      book_title: book.name
    }.to_json
    Rails.logger.info " [x] Publishing order confirmation message: #{message}"
    queue.publish(message, persistent: true)
    Rails.logger.info " [x] Successfully published to order_confirmations queue"
  rescue StandardError => e
    Rails.logger.error " [x] Failed to publish to order_confirmations queue: #{e.message}"
    raise e
  end

  def otp_email(user, otp)
    @user = user
    @otp = otp
    mail(to: user.email, subject: "Your OTP for Password Reset - Book Store")
  end

  def password_reset_success_email(user)
    @user = user
    mail(to: @user.email, subject: "Your Password Has Been Successfully Reset - Book Store")
  end

  def welcome_email(user)
    @user = user
    mail(to: @user.email, subject: "Welcome to Book Store, #{@user.name}!")
  end

  def order_confirmation_email(order)
    @order = order
    @user = order.user
    mail(to: @user.email, subject: "Order Confirmation - Book Store (Order ##{order.id})")
  end
end