host = ENV.fetch("APP_HOST", "localhost:3000")
protocol = Rails.env.production? ? "https" : "http"
Rails.application.routes.default_url_options = { host: host, protocol: protocol }
