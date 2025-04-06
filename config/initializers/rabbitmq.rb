require "bunny"

module RabbitMQ
  def self.create_channel
    if ENV["RABBITMQ_URL"] && !ENV["RABBITMQ_URL"].empty?
      @connection ||= Bunny.new(ENV["RABBITMQ_URL"]).tap(&:start)
    elsif ENV["RABBITMQ_HOST"] && ENV["RABBITMQ_PORT"] && ENV["RABBITMQ_USERNAME"] && ENV["RABBITMQ_PASSWORD"]
      @connection ||= Bunny.new(
        host: ENV["RABBITMQ_HOST"],
        port: ENV["RABBITMQ_PORT"].to_i,
        username: ENV["RABBITMQ_USERNAME"],
        password: ENV["RABBITMQ_PASSWORD"]
      ).tap(&:start)
    else
      raise "Neither RABBITMQ_URL nor required RABBITMQ_* variables (HOST, PORT, USERNAME, PASSWORD) are properly set."
    end
    @connection.create_channel
  end

  def self.close_connection
    @connection&.close if @connection
  end

  at_exit { close_connection }
end