# app/workers/email_worker.rb
require "bunny"
require "json" # Ensure JSON is required for parsing

class EmailWorker
  def self.start
    channel = RabbitMQ.channel
    return unless channel
    queue = channel.queue("otp_emails")

    puts " [*] Waiting for messages in otp_emails queue. To exit, press CTRL+C"

    queue.subscribe(block: true) do |_, _, body|
      message = JSON.parse(body)
      user = User.find_by(email: message["email"])
      if user
        UserMailer.otp_email(user, message["otp"]).deliver_now
        puts " [x] Sent OTP email to #{user.email}"
      end
    end
  rescue Interrupt => _
    channel.close
    puts " [x] Worker interrupted and channel closed"
  end
end
