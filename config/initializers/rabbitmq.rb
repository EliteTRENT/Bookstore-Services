# config/initializers/rabbitmq.rb
require "bunny"

module RabbitMQ
  def self.channel
    @channel ||= begin
      Rails.logger.info "[RabbitMQ] Setting up connection at #{Time.now}"
      # Use RABBITMQ_URL if present, otherwise fall back to individual params
      connection_string = ENV["RABBITMQ_URL"] || {
        host: ENV["RABBITMQ_HOST"] || "beaver.rmq.cloudamqp.com",
        port: ENV["RABBITMQ_PORT"]&.to_i || 5671,
        username: ENV["RABBITMQ_USERNAME"] || "wcuvhlex",
        password: ENV["RABBITMQ_PASSWORD"] || "9jNTYYHBaaAF-16MeIE9gT5OW0q3zbuW",
        vhost: ENV["RABBITMQ_VHOST"] || "wcuvhlex",
        ssl: true
      }
      Rails.logger.info "[RabbitMQ] Connecting with: #{connection_string.inspect}"
      conn = Bunny.new(connection_string)
      conn.start
      channel = conn.create_channel
      Rails.logger.info "[RabbitMQ] Connection established: #{channel.inspect}"
      channel
    rescue Bunny::Exception => e
      Rails.logger.error "[RabbitMQ] Failed to connect: #{e.message}"
      # Don’t raise during build (e.g., test env or Render’s build phase)
      nil unless Rails.env.development? || Rails.env.production?
    end
  end
end
