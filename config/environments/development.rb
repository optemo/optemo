require 'null_object'
require 'will_paginate_tweak'
Site::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  #config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false
  
  # In production, Apache or nginx will already do this
  config.serve_static_assets = true # false by default

  # Enable serving of images, stylesheets, and javascripts from an asset server
  # This used to be "assets.optemo.com" but that requires an entry in /etc/hosts
  # config.action_controller.asset_host = "http://localhost:3000"

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin
  
  if File.exists?(File.join(Rails.root.to_s,'tmp', 'debug.txt'))
     require 'ruby-debug'
     Debugger.wait_connection = true
     Debugger.start_remote
     File.delete(File.join(Rails.root.to_s,'tmp', 'debug.txt'))
  end
  
  #Add jsonp wrapping support
  require 'j_s_padding'
  config.middleware.use JSPadding

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true

end
