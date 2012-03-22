source 'http://rubygems.org'


gem 'rails', '3.1.1'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'yui-compressor'
end

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

#gem 'sqlite3-ruby', :require => 'sqlite3'
gem 'mysql2', '> 0.3'

#gem 'jquery-rails'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'
gem 'capistrano-ext'

gem 'i18n-active_record',
      :git => 'git://github.com/svenfuchs/i18n-active_record.git',
      :require => 'i18n/active_record'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'
gem 'sunspot_rails', :git=> "https://github.com/wildoats/sunspot.git", :branch=>"optemo"
gem 'ruby_core_source'
gem 'progress_bar'
#gem 'sunspot_rails', '2.0.0.optemo', :path => 'vendor/plugins/sunspot'


#gem 'thinking-sphinx', '2.0.1', :require => 'thinking_sphinx'
gem 'will_paginate', '3.0.0'
#gem 'rmagick'

group :production, :profile do
  gem "dalli", "1.0.2"
end

group :development do
   gem 'sunspot_solr', :git=> "https://github.com/wildoats/sunspot.git", :branch=>"optemo" # optional pre-packaged Solr distribution for use in development
   #gem 'sunspot_solr', '2.0.0.optemo', :path => 'vendor/plugins/sunspot' # optional pre-packaged Solr distribution for use in development
end

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
#   gem 'webrat'
  gem "linecache19", "0.5.13", :path => ENV['rvm_path'] + "/gems/ruby-1.9.3-p0/gems/linecache19-0.5.13/"
  gem "ruby-debug-base19", "0.11.26", :path => ENV['rvm_path'] + "/gems/ruby-1.9.3-p0/gems/ruby-debug-base19-0.11.26/"
  gem "ruby-debug19", :require => 'ruby-debug'
end

group :test do
  gem 'spork', '> 0.9.0.rc'
  gem 'spork-testunit'
  gem 'guard-test'
  gem 'guard-spork'
  gem 'rb-fsevent'
  gem 'ruby-prof'
  gem 'growl_notify'
	gem 'factory_girl_rails'
end

