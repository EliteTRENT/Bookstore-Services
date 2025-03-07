require "bunny"

module RabbitMQ
  def self.create_channel
    @connection ||= Bunny.new(
      host: ENV["RABBITMQ_HOST"],
      port: ENV["RABBITMQ_PORT"],
      username: ENV["RABBITMQ_USERNAME"],
      password: ENV["RABBITMQ_PASSWORD"]
    ).tap(&:start)
    @connection.create_channel
  end

  at_exit { @connection&.close }
end
