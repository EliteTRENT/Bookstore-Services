require "bunny"

class WelcomeEmailWorker
  def self.start
    loop do
      begin
        puts " [*] Connecting to RabbitMQ and waiting for messages in 'welcome_emails' queue..."
        channel = RabbitMQ.create_channel
        queue = channel.queue("welcome_emails")

        puts " [*] Waiting for messages in 'welcome_emails' queue. To exit manually, stop the service."

        queue.subscribe(block: true) do |delivery_info, properties, body|
          message = JSON.parse(body)
          user = User.find_by(email: message["email"])
          if user
            UserMailer.welcome_email(user).deliver_now
            puts " [x] Sent welcome email to #{user.email}"
          else
            puts " [x] Failed to send welcome email: No user found for email #{message['email']}"
          end
        end
      rescue Bunny::TCPConnectionFailed => e
        puts " [x] RabbitMQ connection failed: #{e.message}. Retrying in 5 seconds..."
        sleep 5
      rescue JSON::ParserError => e
        puts " [x] Failed to parse message: #{e.message}. Retrying in 5 seconds..."
        sleep 5
      rescue StandardError => e
        puts " [x] Error processing message: #{e.message}. Retrying in 5 seconds..."
        sleep 5
      ensure
        RabbitMQ.close_connection # Clean up connection on error or loop iteration
      end
    rescue Interrupt => _
      puts " [x] Shutting down WelcomeEmailWorker..."
      RabbitMQ.close_connection
    end
  end
end
