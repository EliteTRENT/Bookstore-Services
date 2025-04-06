require "bunny"
class OrderConfirmationWorker
  def self.start
    loop do
      begin
        puts " [*] Connecting to RabbitMQ and waiting for messages in 'order_confirmations' queue..."
        channel = RabbitMQ.create_channel
        queue = channel.queue("order_confirmations")

        puts " [*] Waiting for messages in 'order_confirmations' queue. To exit manually, stop the service."

        queue.subscribe(block: true) do |delivery_info, properties, body|
          message = JSON.parse(body)
          user = User.find_by(email: message["email"])
          order = Order.find_by(id: message["order_id"])
          if user && order
            UserMailer.order_confirmation_email(order).deliver_now
            puts " [x] Sent order confirmation email to #{user.email} for Order ##{order.id}"
          else
            puts " [x] Failed to send order confirmation email: User or Order not found for email #{message['email']} and order_id #{message['order_id']}"
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
    end
  rescue Interrupt => _
    puts " [x] Shutting down OrderConfirmationWorker..."
    RabbitMQ.close_connection
  end
end