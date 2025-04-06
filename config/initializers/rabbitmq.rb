require "bunny"

module RabbitMQ
  def self.create_channel
    @connection ||= Bunny.new(
      ENV["RABBITMQ_URL"]
    ).tap(&:start)
    @connection.create_channel
  end

  def self.close_connection
    @connection&.close if @connection
  end
  at_exit { close_connection }
end
