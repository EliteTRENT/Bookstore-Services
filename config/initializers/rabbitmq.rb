# config/initializers/rabbitmq.rb
require "bunny"

begin
  Rails.logger.info "Starting RabbitMQ connection setup"
  conn = Bunny.new(
    host: ENV["RABBITMQ_HOST"] || "beaver.rmq.cloudamqp.com",
    port: ENV["RABBITMQ_PORT"]&.to_i || 5671,
    username: ENV["RABBITMQ_USERNAME"] || "wcuvhlex",
    password: ENV["RABBITMQ_PASSWORD"] || "9jNTYYHBaaAF-16MeIE9gT5OW0q3zbuW",
    vhost: ENV["RABBITMQ_VHOST"] || "wcuvhlex",
    ssl: true
  )
  conn.start
  CHANNEL = conn.create_channel
  Rails.logger.info "RabbitMQ connection established and CHANNEL created: #{CHANNEL.inspect}"
rescue Bunny::Exception => e
  Rails.logger.error "Failed to connect to RabbitMQ: #{e.message}"
  raise e # Raise to halt the app and make the failure obvious
end
