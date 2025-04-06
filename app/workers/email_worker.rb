require "bunny"

class EmailWorker
  def self.start
    loop do
      begin
        puts " [*] Connecting to RabbitMQ and waiting for messages in 'otp_emails' queue..."
        channel = RabbitMQ.create_channel
        queue = channel.queue("otp_emails")

        puts " [*] Waiting for messages in 'otp_emails' queue. To exit manually, stop the service."

        queue.subscribe(block: true) do |delivery_info, properties, body|
          message = JSON.parse(body)
          user = User.find_by(email: message["email"])
          if user
            UserMailer.otp_email(user, message["otp"]).deliver_now
            puts " [x] Sent OTP email to #{user.email}"
          else
            puts " [x] No user found for email: #{message['email']}"
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
        RabbitMQ.close_connection # Clean up connection on error or exit
      end
    rescue Interrupt => _
      puts " [x] Shutting down EmailWorker..."
      RabbitMQ.close_connection
    end
  end
end