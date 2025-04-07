# app/workers/welcome_email_worker.rb
require "bunny"
require "json" # Ensure JSON is required for parsing

class WelcomeEmailWorker
  def self.start
    channel = RabbitMQ.channel
    return unless channel
    queue = channel.queue("welcome_emails")

    puts " [*] Waiting for messages in welcome_emails queue. To exit, press CTRL+C"

    queue.subscribe(block: true) do |_, _, body|
      message = JSON.parse(body)
      user = User.find_by(email: message["email"])
      if user
        UserMailer.welcome_email(user).deliver_now
        puts " [x] Sent welcome email to #{user.email}"
      end
    end
  rescue Interrupt => _
    channel.close
    puts " [x] Worker interrupted and channel closed"
  end
end
