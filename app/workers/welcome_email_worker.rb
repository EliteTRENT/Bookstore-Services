require "bunny"

class WelcomeEmailWorker
  def self.start
    channel = RabbitMQ.create_channel
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
  end
end