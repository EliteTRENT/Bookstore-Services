Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*" # Allow all origins; change to specific domains if needed
    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options ],
      expose: [ "Authorization" ]
  end
end
