require "bunny"

class OtpWorker
  def self.start
    puts "Starting OTP email worker..."

    conn = Bunny.new(
      host: ENV["RABBITMQ_HOST"],
      port: ENV["RABBITMQ_PORT"],
      username: ENV["RABBITMQ_USERNAME"],
      password: ENV["RABBITMQ_PASSWORD"]
    )
    conn.start

    channel = conn.create_channel
    queue = channel.queue("otp_emails", durable: false)

    puts "Waiting for OTP emails in queue 'otp_emails'..."

    queue.subscribe(block: true, manual_ack: true) do |delivery_info, properties, body|
      begin
        puts "Received message: #{body}"
        data = JSON.parse(body)
        email = data["email"] # Use email instead of user_id
        otp = data["otp"]

        raise "Missing or invalid email: #{email.inspect}" unless email.present?

        user = User.find_by(email: email)
        raise "User not found for email: #{email}" unless user

        UserMailer.otp_email(user, otp).deliver_now
        puts "Sent OTP email to #{user.email} with OTP: #{otp}"

        channel.ack(delivery_info.delivery_tag)
      rescue StandardError => e
        puts "Error processing message: #{e.message}"
        channel.nack(delivery_info.delivery_tag, false, true)
      end
    end

    at_exit { conn.close }
  end
end
