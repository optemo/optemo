set :application, "staging"
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
set :use_sudo, false


role :app, domain
role :web, domain
role :db,  domain, :primary => true

############################################################
#	Passenger
#############################################################
desc "Compile C-Code"
task :compilec do
  run "cd #{current_path}/lib/c_code/clusteringCodes/ && make hCluster"
end

desc "Configure the server files"
task :serversetup do
  # Instantiate the database.yml file
  run "cd #{current_path}/config              && cp -f database.yml.deploy database.yml"
  run "cd #{current_path}/config/ultrasphinx   && cp -f development.conf.deploy development.conf && cp -f production.conf.deploy production.conf"
end
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
after :deploy, "serversetup"
after :serversetup, "deploy:after_update_code"
after :after_update_code, "compilec"
after :compilec, "deploy:restart"


