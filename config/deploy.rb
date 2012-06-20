set :stages, %w(sbox production linode slicehost sandbox fremont uniserve)
set :rvm_type, :system
set :rvm_ruby_string, '1.9.3'
require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require "rvm/capistrano"                  # Load RVM's capistrano plugin.

