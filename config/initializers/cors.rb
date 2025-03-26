# Rails.application.config.middleware.insert_before 0, Rack::Cors do
#   allow do
#     origins "http://localhost:8080" # Replace with Swagger UI's origin
#     resource "*", headers: :any, methods: [ :get, :post, :put, :patch, :delete, :options, :head ]
#   end
# end


# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*" # Allow all origins; change to specific domains if needed
    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options ],
      expose: [ "Authorization" ]
  end
end
