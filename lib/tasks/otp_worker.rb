require "bunny"

class OtpWorker
  def self.start
    loop do
      begin
        puts " [*] Connecting to RabbitMQ and waiting for messages in 'otp_emails' queue..."
        channel = RabbitMQ.create_channel
        queue = channel.queue("otp_emails", durable: false)

        puts " [*] Waiting for OTP emails in queue 'otp_emails'..."

        queue.subscribe(block: true, manual_ack: true) do |delivery_info, properties, body|
          begin
            puts "Received message: #{body}"
            data = JSON.parse(body)
            email = data["email"]
            otp = data["otp"]

            raise "Missing or invalid email: #{email.inspect}" unless email.present?

            user = User.find_by(email: email)
            raise "User not found for email: #{email}" unless user

            UserMailer.otp_email(user, otp).deliver_now
            puts "Sent OTP email to #{user.email} with OTP: #{otp}"

            channel.ack(delivery_info.delivery_tag)
          rescue JSON::ParserError => e
            puts " [x] Failed to parse message: #{e.message}"
            channel.nack(delivery_info.delivery_tag, false, true)
          rescue StandardError => e
            puts " [x] Error processing message: #{e.message}"
            channel.nack(delivery_info.delivery_tag, false, true)
          end
        end
      rescue Bunny::TCPConnectionFailed => e
        puts " [x] RabbitMQ connection failed: #{e.message}. Retrying in 5 seconds..."
        sleep 5
      rescue StandardError => e
        puts " [x] Error during subscription setup: #{e.message}. Retrying in 5 seconds..."
        sleep 5
      ensure
        RabbitMQ.close_connection # Clean up connection on error or loop iteration
      end
    rescue Interrupt => _
      puts " [x] Shutting down OtpWorker..."
      RabbitMQ.close_connection
    end
  end
end