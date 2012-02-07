desc "Restarts passenger if in debug mode"
task :restart do
  system("touch tmp/restart.txt")
  system("touch tmp/debug.txt") if ENV["DEBUG"] == 'true'
end

namespace :cache do
  desc 'Clear memcache'
  task :clear => :environment do
    Rails.cache.clear if Rails.cache && Rails.cache.respond_to?(:clear)
  end
end

desc 'Create YAML test fixtures from data in an existing database.  
Defaults to development database.  Set RAILS_ENV to override.'

task :extract_fixtures => :environment do
  #sql  = "SELECT * FROM %s where (product_type = 'printer_us' and version = 12) or product_type = 'camera_us'"
  sql = "SELECT * FROM %s"
  ActiveRecord::Base.establish_connection
  table_name = ENV["T"]
    i = "000"
    File.open("#{Rails.root}/test/fixtures/#{table_name}.yml", 'w') do |file|
      data = ActiveRecord::Base.connection.select_all(sql % table_name)
      myhash = {}
      file.write data[0..20000].inject(myhash) { |hash, record|
        hash["#{table_name}_#{i.succ!}"] = record
        hash
      }.to_yaml
      myhash = {}
      file.write data[20000..40000].inject(myhash) { |hash, record|
        hash["#{table_name}_#{i.succ!}"] = record
        hash
      }.to_yaml unless data[20000..40000].nil?
      myhash = {}
      file.write data[40000..-1].inject(myhash) { |hash, record|
        hash["#{table_name}_#{i.succ!}"] = record
        hash
      }.to_yaml unless data[40000..-1].nil?
    end
end