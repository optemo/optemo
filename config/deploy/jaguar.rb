set :application, "optemo_site"
set :repository,  "git@jaguar:site.git"
set :domain, "jaguar"
set :branch, "staging"
set :user, 'jan'

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
# set :deploy_to, "/var/www/#{application}"

set :scm, :git
set :deploy_via, :remote_cache
#ssh_options[:paranoid] = false
default_run_options[:pty] = true
set :use_sudo, true
set :runner, 'jan'


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
  sudo "rake -f #{current_path}/Rakefile ultrasphinx:index RAILS_ENV=production"
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
  run "cd #{current_path}/config/ultrasphinx   && cp -f development.conf.deploy development.conf && cp -f production.conf.deploy production.conf"
end

after :deploy, "serversetup"
after :serversetup, "deploy:after_update_code"
after :after_update_code, "deploy:restart"


