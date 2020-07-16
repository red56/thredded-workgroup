# frozen_string_literal: true

Dummy::Application.configure do
  # IMPORTANT: Mandatory for Thredded::Workgroup dummy (development)
  require "rack-livereload"
  # guard-livereload needs the rack middeleware:
  config.middleware.insert_after(
    ActionDispatch::Static, Rack::LiveReload,
    port: ENV["LIVERELOAD_PORT"]&.to_i || 35_734
  )

  config.eager_load = false

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Show full error reports and disable caching
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  config.action_controller.action_on_unpermitted_parameters = :raise

  config.action_mailer.perform_deliveries = false
  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

  config.reload_plugins = true

  config.action_mailer.default_url_options = {
    # IMPORTANT: Mandatory for Thredded::Workgroup dummy
    host: "localhost:9292"
  }

  if File.file?("/.dockerenv")
    docker_host_ip = `/sbin/ip route|awk '/default/ { print $3 }'`.strip
    config.web_console.permissions = docker_host_ip
  end

  # Allow webpack-dev-server
  if Rails.gem_version >= Gem::Version.new("6.0.0")
    Rails.application.config.content_security_policy do |policy|
      policy.connect_src :self, :https, "http://localhost:3035", "ws://localhost:3035" if Rails.env.development?
    end
  end
end
