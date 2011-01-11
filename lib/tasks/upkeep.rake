desc "Run boostexter to generate strong hypothesis files or Parse boostexter strong hypothesis files and save in database"
task :btxtr => :environment do
     $: << "#{Rails.root}/lib/cluster_labeling/boostexter_labels_rb"
     
     unless ENV.include?("url") && ENV.include?("action") && (ENV['action']=='save' || ENV['action']=='train')
          raise "usage: rake btxtr url=? action=? # url is a valid url from products.yml and action is 'save' or 'train'" 
     end
     
     s = Session.new(ENV['url'])
     s.version = Cluster.maximum(:version, :conditions => ['product_type = ?', s.product_type]) if s.directLayout
     case ENV['action']
     when 'train'
       require 'train_boostexter.rb'
       BtxtrLabels.train_boostexter_on_all_clusters()
     when 'save'
       require 'combined_rules.rb'
       BtxtrLabels.save_combined_rules_for_all_clusters()
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