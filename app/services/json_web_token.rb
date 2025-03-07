class JsonWebToken
  def self.encode(payload)
    token = JWT.encode(payload, ENV["SECRET_KEY"], "HS256")
    token
  end
end
