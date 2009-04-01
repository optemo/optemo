set :application, "optemo_site"
set :repository,  "git@jaguar:site.git"
set :domain, "jaguar"
set :branch, "staging"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

set :scm, :git
set :deploy_via, :remote_cache
set :user, 'jan'
#ssh_options[:paranoid] = false
default_run_options[:pty] = true
set :use_sudo, false
set :restart, "/etc/init.d/apache2 restart"


role :app, domain
role :web, domain
role :db,  domain, :primary => true

############################################################
#	Passenger
#############################################################

namespace :passenger do
  desc "Restart Application"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

desc "Compile C-Code"
task :compilec do
  run "cp -rf #{current_path}/lib/c_code/clusteringCodeLinux/* #{current_path}/lib/c_code/clusteringCode"
  run "cd #{current_path}/lib/c_code/clusteringCode/ && make clean && make connect"
end

desc "Configure the server files"
task :serversetup do
  # Instantiate the database.yml file
  run "cd #{current_path}/config              && cp -f database.yml.deploy database.yml"
end

after :deploy, "serversetup"
after :serversetup, "compilec"
after :compilec, "passenger:restart"


