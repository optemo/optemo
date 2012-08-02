set :application, "production"
set :repository,  "git@jaguar:site.git"
set :domains, %w(linode1 linode2 linode3 linode4 linode5 rackspace1 rackspace2 rackspace3)
role(:app) { domains }
role(:web) { domains }
role :memcached, "linode1", "rackspace1"
set :branch, "staging"
set :user, "#{ `whoami`.chomp }"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

set :scm, :git
set :deploy_via, :remote_cache
#ssh_options[:paranoid] = false
default_run_options[:pty] = true
# The above command allows for interactive commands like entering ssh passwords, but
# the problem is that "umask = 002" is getting ignored, since .profile isn't being sourced.
# :pty => true enables for a given command if we set the above to false eventually
# ssh_options[:port] = 5151   # Re-enable if we are deploying remotely again
set :use_sudo, false
# There is also this method, might be better in some cases:
# { Capistrano::CLI.ui.ask("User name: ") }

load 'deploy/assets'
load 'config/deploy/recipes'

before 'deploy:update', :set_umask
before "deploy:assets:precompile", :serversetup
after "deploy:create_symlink", :restartmemcached
after :restartmemcached, :redopermissions
after "deploy:restart", :warmupserver