Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://127.0.0.1:23847'

    resource '/api/auth/*',
             headers: :any,
             methods: [:post],
             credentials: false
  end

  allow do
    # origins 'http://localhost:3000'
    origins '*'

    resource '*',
             headers: :any,
             methods: [:get]
  end
end
