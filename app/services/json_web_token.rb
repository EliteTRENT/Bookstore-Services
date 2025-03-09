class JsonWebToken
  def self.encode(payload)
    JWT.encode(payload, ENV["SECRET_KEY"], "HS256")
  end

  def self.decode(token)
    begin
      decoded_token = JWT.decode(token, ENV["SECRET_KEY"], true, algorithm: "HS256")
      decoded_token[0]["email"]
    rescue JWT::DecodeError
      nil
    end
  end
end
