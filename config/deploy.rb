set :application, "optemo_site"
set :repository,  "git@jaguar:site.git"
set :domain, "jaguar"

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
  run "make #{current_path}/lib/c_code/clusteringCode/codes/connect"
end

after :deploy, "compilec"
after :compilec, "passenger:restart"