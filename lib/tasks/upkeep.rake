require 'GlobalDeclarations'
#Here is where general upkeep scripts are
desc "Calculate factors for all features of all products, and pre-calculate utility scores"
task :calculate_factors => :environment do
  # Truncate the existing factors table
  ActiveRecord::Base.connection.execute('TRUNCATE factors')
  file = YAML::load(File.open("#{RAILS_ROOT}/config/products.yml"))
  unless (file.nil? || file.empty?)
    product_types = {}
    # The reason for setting up this hash is that we want only the base product types, 
    # but need the associated URL in order to access the filter features via products.yml
    # ** warning: if there are multiple url entries with the same product_type but different filter specs, it will take the filter specs that were defined last.
    # ** This is a limitation that should be taken care of some day.
    # ** Example: 'builddirect.optemo.com' and 'flooring' both have entries in products.yml, so if 'flooring' did not have "species_hardness: [filter]" defined
    # ** As a result, this overrides the entry for builddirect.optemo.com, and is probably undesirable.
    file.each do |p_yml_entry|
      product_types[p_yml_entry.second["product_type"].first] = (p_yml_entry.first)
    end
    factor_activerecords = []
    utility_activerecords = []
    product_types.each do |pType_url_pair| # This is a pair like this: "camera_us"=>"m.browsethenbuy.com" - seems backwards, but makes the hash unique on product_type
      cont_spec_hash = {}
      load_defaults(pType_url_pair[1]) # Need to set up $Continuous and other arrays before use
      all_products = Product.valid.instock
      all_products.each do |product|
        newUtilityRow = ContSpec.new({:product_type => pType_url_pair[0], :name => "utility", :product_id => product.id, :value => 0})
        $Continuous["filter"].each do |f|
          unless cont_spec_hash[f]
            records = ContSpec.find(:all, :select => 'product_id, value', :conditions => ["product_id IN (?) and name = ?", all_products, f])
            temp_hash = {}
            records.each do |r| # Strip the records down to {id => value} pairs
              temp_hash[r.product_id] = r.value
            end
            cont_spec_hash[f] = temp_hash
          end
          newFactorRow = Factor.new({:product_id => product.id, :product_type => pType_url_pair[0], :cont_var => f})
          fVal = cont_spec_hash[f][product.id]
          debugger unless fVal # The alternative here is to crash. This should never happen if Product.valid.instock is doing its job.
          newFactorRow.value = calculateFactor(fVal, f, cont_spec_hash[f])
          factor_activerecords.push(newFactorRow)
          # Now that we have the factor value for that row, add it to the utility
          newUtilityRow.value += newFactorRow.value
        end
        utility_activerecords.push(newUtilityRow)
      end
    end
    # Do all record saving at the end for efficiency
    Factor.transaction do
      factor_activerecords.each(&:save)
    end
    ContSpec.delete_all(["name = ?", "utility"])
    ContSpec.transaction do
      utility_activerecords.each(&:save)
    end    
  end
end

desc "Run boostexter to generate strong hypothesis files or Parse boostexter strong hypothesis files and save in database"
task :btxtr => :environment do
     $: << "#{RAILS_ROOT}/lib/cluster_labeling/boostexter_labels_rb"
     
     unless ENV.include?("url") && ENV.include?("action") && (ENV['action']=='save' || ENV['action']=='train')
          raise "usage: rake btxtr url=? action=? # url is a valid url from products.yml and action is 'save' or 'train'" 
     end
     
     load_defaults(ENV['url'])
     # Not 100% sure this next line is needed. It replaced "Session.current = Session.new"
     Session.current = Session.new(0, Cluster.maximum(:version, :conditions => ['product_type = ?', $product_type]))
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
  ordered = ordered.reverse if $PrefDirection[f] == 1
  return 0 if $PrefDirection[f] == 0
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
      `#{RAILS_ROOT}/lib/c_code/clusteringCodes/codes/hCluster #{prodtype} #{region} #{env} #{$NumGroups}`
      cleanupInvalidDatabase(prodtype)
    end
  end
end

desc "Recluster printers"
task :recluster => [:calculate_factors,:c_clustering] do
  Rake::Task['db:properties'].invoke
end