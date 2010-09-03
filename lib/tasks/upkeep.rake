#Here is where general upkeep scripts are
desc "Calculate factors for all features of all products, and pre-calculate utility scores"
task :calculate_factors => :environment do
  # Do not truncate Factor table anymore. Instead, add more factors for the given URL.
  file = YAML::load(File.open("#{Rails.root}/config/products.yml"))
  unless ENV.include?("url") && (s = Session.new(ENV["url"])) && file[ENV["url"]] && (!ENV.include?("version") || (ENV.include?("version") && ENV["version"].to_i.to_s == ENV["version"] && ENV["version"].to_i >= 0))
    raise "usage: rake calculate_factors url=? (version=?) # url is a valid url from products.yml; sets product_type. `version` is optional; if not supplied, the version number will be incremented based on the maximum existing factor version for that product_type."
  end
  
  if ENV.include?("version")
    version = ENV["version"].to_i # We did error checking above already. If this exists, it's an integer.
  else
    factor_version = Factor.maximum(:version, :conditions => ['product_type = ?', s.product_type]).to_i + 1 # Automatically increment the version number from existing factors.
    cluster_version = Cluster.maximum(:version, :conditions => ['product_type=?', s.product_type]).to_i + 1
    version = [cluster_version, factor_version].max
  end
  factor_activerecords = []
  utility_activerecords = []
  cont_spec_local_cache = {} # This saves doing many ContSpec lookups. It's a hash with {id => value} pairs
  all_products = Product.valid.instock
  all_products.each do |product|
    newUtilityRow = ContSpec.new({:product_type => s.product_type, :name => "utility", :product_id => product.id, :value => 0})
    s.continuous["filter"].each do |f|
      unless cont_spec_local_cache[f]
        records = ContSpec.find(:all, :select => 'product_id, value', :conditions => ["product_id IN (?) and name = ?", all_products, f])
        temp_hash = {}
        records.each do |r| # Strip the records down to {id => value} pairs
          temp_hash[r.product_id] = r.value
        end
        cont_spec_local_cache[f] = temp_hash
      end
      newFactorRow = Factor.new({:product_id => product.id, :product_type => s.product_type, :cont_var => f, :version => version})
      fVal = cont_spec_local_cache[f][product.id]
      debugger unless fVal # The alternative here is to crash. This should never happen if Product.valid.instock is doing its job.
      newFactorRow.value = calculateFactor(fVal, f, cont_spec_local_cache[f])
      factor_activerecords.push(newFactorRow)
      # Now that we have the factor value for that row, add it to the utility
      newUtilityRow.value += newFactorRow.value
    end
    utility_activerecords.push(newUtilityRow)
  end
  # Do all record saving at the end for efficiency
  Factor.transaction do
    factor_activerecords.each(&:save)
  end
  ContSpec.delete_all(["name = ?", "utility"]) # ContSpec records do not have a version number, so we have to wipe out the old ones.
  ContSpec.transaction do
    utility_activerecords.each(&:save)
  end    
end

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

desc "Assign lowest price to printers"
task :assign_lowest_price => :environment do
  Printer.find(:all, :conditions => ['created_at > ?', 4.days.ago]).each do |p|
    #Find lowest product price
    os = RetailerOffering.find_all_by_product_id_and_product_type(p.id,p.class.name)
    lowest = 1000000000
    p.instock = false
    if !os.nil? && !os.empty?
      os.each do |o| 
        if o.stock && o.priceint && o.priceint < lowest
          lowest = o.priceint
          p.price = lowest
          p.pricestr = o.pricestr
          p.bestoffer = o.id
          p.instock = true
        end
      end
    end
    p.save
  end
end

def calculateFactor(fVal, f, contspecs)
  # Order the feature values, reversed to give the highest value to duplicates
  ordered = contspecs.values.sort
  ordered = ordered.reverse if Session.current.prefDirection[f] == 1
  return 0 if Session.current.prefDirection[f] == 0
  pos = ordered.index(fVal)
  len = ordered.length
  (len - pos)/len.to_f
end

desc "Run c-code to recluster"
task :c_clustering do
  require 'helpers/clusteringLogCheckLinux'
  include Clusteringlogchecklinux
  env = ENV['RAILS_ENV'] || 'development'
  ['printer', 'camera'].each do |prodtype|
    ['us','ca'].each do |region|
      `#{Rails.root}/lib/c_code/clusteringCodes/codes/hCluster #{prodtype} #{region} #{env} #{Session.current.numGroups}`
      cleanupInvalidDatabase(prodtype)
    end
  end
end

desc "Recluster printers"
task :recluster => [:calculate_factors,:c_clustering] do
  Rake::Task['db:properties'].invoke
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