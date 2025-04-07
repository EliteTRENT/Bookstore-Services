require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests in production.
  config.enable_reloading = false

  # Eager load code on boot to improve performance and catch errors early.
  config.eager_load = true

  # Do not show full error reports to users; use a generic error page instead.
  config.consider_all_requests_local = false

  # Enable server timing for performance monitoring (optional, keep if you use it).
  config.server_timing = true

  # Enable caching for better performance.
  config.action_controller.perform_caching = true
  config.action_controller.enable_fragment_cache_logging = true # Optional, for debugging
  config.public_file_server.headers = { "Cache-Control" => "public, max-age=#{1.year.to_i}" } # Long cache for static assets

  # Use a real caching store (e.g., Memcached or Redis) instead of memory_store.
  # Render supports Redis; uncomment and configure if you add it.
  # config.cache_store = :redis_cache_store, { url: ENV["REDIS_URL"] }
  config.cache_store = :memory_store # Temporary, switch to Redis for production scale

  # Store uploaded files (e.g., Active Storage). Use Render’s disk or an external service like S3.
  config.active_storage.service = :local # Change to :amazon or :render_disk if configured

  # **EMAIL CONFIGURATION**
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = false # Don’t raise errors in production; log them instead
  config.action_mailer.smtp_settings = {
    address: "smtp.gmail.com",
    port: 587,
    domain: "gmail.com",
    user_name: ENV["EMAIL_USERNAME"], # Set in Render’s environment variables
    password: ENV["EMAIL_PASSWORD"],  # Use Gmail App Password, set in Render
    authentication: "plain",
    enable_starttls_auto: true,
    open_timeout: 10,
    read_timeout: 10
  }
  # Set the production host for email URLs (Render provides this).
  config.action_mailer.default_url_options = { host: ENV["RENDER_EXTERNAL_HOSTNAME"] || "your-app-name.onrender.com" }

  # Log deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Don’t check for pending migrations on page load in production; handle during deploy.
  config.active_record.migration_error = false

  # Log database queries with runtime info (optional, disable if logs get too noisy).
  config.active_record.verbose_query_logs = false
  config.active_record.query_log_tags_enabled = true

  # Log background job enqueuing (optional).
  config.active_job.verbose_enqueue_logs = true

  # Raise error for missing translations (optional, enable if needed).
  # config.i18n.raise_on_missing_translations = true

  # Annotate views with filenames (optional, disable in production unless debugging).
  config.action_view.annotate_rendered_view_with_filenames = false

  # Ensure SSL is enforced (Render handles this, but good to set).
  config.force_ssl = true

  # Configure logging level (adjust based on needs).
  config.log_level = :info # :debug for more detail, :info for less noise

  # Use a more robust logger for production.
  config.logger = ActiveSupport::Logger.new(STDOUT)
  config.log_formatter = ::Logger::Formatter.new

  # Raise error for missing callback actions.
  config.action_controller.raise_on_missing_callback_actions = true
end
