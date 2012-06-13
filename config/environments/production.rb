require 'null_object'
require 'will_paginate_tweak'
Site::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The production environment is meant for finished, "live" apps.
  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Specifies the header that your server uses for sending files
  config.action_dispatch.x_sendfile_header = "X-Sendfile"

  # For nginx:
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'

  # If you have no front-end server that supports something like X-Sendfile,
  # just comment this out and Rails will serve the files

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store
  # 86400 = 1.day
  config.cache_store = :dalli_store, '127.0.0.1:11211',
      { :namespace => "OPT", :expires_in => 86400, :compress => true, :compress_threshold => 64*1024 }
  
  # Disable Rails's static asset server
  # In production, Apache or nginx will already do this
  config.serve_static_assets = true # false by default; true for asset_packager

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Choose the compressors to use
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :yui

  # Don't fallback to assets pipeline if a precompiled asset is missed
  # Set to true as a workaround to Rails 3.1.0 bug -- rails 3-1-stable has a fix
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true
  #Add our custom BB files
  config.assets.precompile += ['loader.js','bestbuy.css','futureshop.css']

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Enable serving of images, stylesheets, and javascripts from an asset server
  #config.action_controller.asset_host = "http://ast0.optemo.com"
  #config.action_controller.asset_host = "http://localhost:3000"

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
  
  #Add jsonp wrapping support
  require 'j_s_padding'
  config.middleware.use JSPadding
  
end

#create a new connection to memcached for forked processes, as a forked process will by default share file descriptors with its parent
if defined?(PhusionPassenger)
  PhusionPassenger.on_event(:starting_worker_process) do |forked|
    # Only works with DalliStore
    Rails.cache.reset if forked
  end
end