require "bunny"

class OrderConfirmationWorker
  def self.start
    channel = RabbitMQ.create_channel
    queue = channel.queue("order_confirmations")

    puts " [*] Waiting for messages in order_confirmations queue. To exit, press CTRL+C"

    queue.subscribe(block: true) do |_, _, body|
      message = JSON.parse(body)
      user = User.find_by(email: message["email"])
      order = Order.find_by(id: message["order_id"])
      if user && order
        UserMailer.order_confirmation_email(order).deliver_now
        puts " [x] Sent order confirmation email to #{user.email} for Order ##{order.id}"
      else
        puts " [x] Failed to send order confirmation email: User or Order not found for email #{message["email"]} and order_id #{message["order_id"]}"
      end
    end
  rescue Interrupt => _
    channel.close
  end
end