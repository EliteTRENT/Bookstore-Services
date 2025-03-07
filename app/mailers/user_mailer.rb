class UserMailer < ApplicationMailer
  default from: "aryannegi522@gmail.com"

  def self.enqueue_otp_email(user, otp)
    channel = RabbitMQ.create_channel
    queue = channel.queue("otp_emails")
    message = { email: user.email, otp: otp }.to_json
    queue.publish(message, persistent: true)
    channel.close # Close channel after publishing
  end

  def otp_email(user, otp)
    @user = user
    @otp = otp
    mail(to: @user.email, subject: "Your OTP for Password Reset - Book Store")
  end

  def password_reset_success_email(user)
    @user = user
    mail(to: @user.email, subject: "Your Password Has Been Successfully Reset - Book Store")
  end
end
