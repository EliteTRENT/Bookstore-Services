# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins "http://localhost:8080" # Replace with Swagger UI's origin
#     resource "*", headers: :any, methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
#   end
# end


# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://127.0.0.1:5500" # Frontend URL

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options ],
      credentials: false
  end
end
