require 'GlobalDeclarations'
#Here is where general upkeep scripts are

desc "Calculate factors for all features of all products"
task :calculate_factors => :environment do
    # Truncate the existing factors table
    ActiveRecord::Base.connection.execute('TRUNCATE factors')
    $ProdTypeList.each do |pType|
      products = pType.constantize.valid.instock
      products.each do |product|
        newFactorRow = Factor.new
        newFactorRow.product_id = product.id 
        newFactorRow.product_type = pType
        pType.constantize::ContinuousFeatures.each do |f|
          fVal = product.send(f.intern) 
          result = calculateFactor(products, fVal, f)
          newFactorRow.send((f+'=').intern, result)
        end
        newFactorRow.save
      end
    end   
end

desc "Run boostexter to generate strong hypothesis files or Parse boostexter strong hypothesis files and save in database"
task :btxtr => :environment do
     $: << "#{RAILS_ROOT}/lib/cluster_labeling/boostexter_labels_rb"
     
     unless ENV.include?("type") && ENV.include?("action") && (ENV['action']=='save' || ENV['action']=='train')
          raise "usage: rake btxtr type=? action=? # type is on of the current product types and action is 'save' or 'train'" 
     end
     
     Session.current=Session.new
     load_defaults(ENV['type'])
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

def calculateFactor(products, fVal, f)
  #Order the feature values, reversed to give the highest value to duplicates
  ordered = products.map{|p|p.send(f.intern)}.sort
  ordered = ordered.reverse if $PrefDirection[f] == 1
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