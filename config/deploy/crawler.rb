set :application, "crawler"
set :repository,  "git@jaguar:site.git"
set :domain, "jaguar"
set :branch, "staging"
set :user, "#{ `whoami`.chomp }"
# There is also this method, might be better in some cases:
# { Capistrano::CLI.ui.ask("User name: ") }

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
set :use_sudo, false

role :app, domain
role :web, domain
role :db,  domain, :primary => true

############################################################
#	Passenger
#############################################################

namespace :deploy do
desc "Sync the public/assets directory."
  task :assets do
    system "rsync -vr --exclude='.DS_Store' public/system #{user}@#{domain}:#{shared_path}"
  end
  desc "Restart Application"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
  desc "Create asset packages for production" 
  task :after_update_code, :roles => [:web] do
    run <<-EOF
      cd #{release_path} && rake asset:packager:build_all
    EOF
  end
end

desc "Reindex search index"
task :reindex do
  run "rake -f #{current_path}/Rakefile ts:conf RAILS_ENV=production"
  sudo "rake -f #{current_path}/Rakefile ts:rebuild RAILS_ENV=production"
end

desc "Compile C-Code"
task :compilec do
  run "cp -rf #{current_path}/lib/c_code/clusteringCodeLinux/* #{current_path}/lib/c_code/clusteringCode"
  run "cd #{current_path}/lib/c_code/clusteringCode/"
  sudo "cmake ."
  run "cd codes"
  sudo "make hCluster"
end

desc "Configure the server files"
task :serversetup do
  hc_path = "#{current_path}/lib/c_code/clusteringCodes/codes"
  # Instantiate the database.yml file
  run "cd #{current_path}/config              && cp -f database.yml.deploy database.yml"
  # Link to precompiled hCluster file
  run "cd #{hc_path} && ln -s hCluster-jaguar hCluster"
end

after :deploy, "serversetup"
after :serversetup, "reindex"


