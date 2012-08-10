############################################################
#	Passenger
#############################################################
namespace :deploy do
  desc "Restart Application"
  task :restart do
    run "touch #{current_path}/tmp/restart.txt"
  end
end

desc "Configure the server files"
task :serversetup do
  # Instantiate the database.yml file
  run "cd #{latest_release}/config              && cp -f database.yml.deploy database.yml"
  run "cd #{latest_release}/config              && cp -f sunspot.yml.deploy sunspot.yml"
  #run "cd #{current_path}/config/ultrasphinx   && cp -f development.conf.deploy development.conf && cp -f production.conf.deploy production.conf"
end

task :restartmemcached, roles: :memcached do # Found this idea. Maybe consider it for when memcached crashes? :only => {:memcached => true}
  run "cd #{current_path} && bundle exec rake cache:clear RAILS_ENV=production"
end

task :redopermissions do
  run "find #{current_path} #{current_path}/../../shared -user `whoami` ! -perm /g+w -execdir chmod g+w {} +"
end

task :warmupserver do
  run "curl -A 'Java' localhost > /dev/null"
end

task :set_umask do
  run "umask 0002"
end