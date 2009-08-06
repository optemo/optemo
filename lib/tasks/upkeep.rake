require 'GlobalDeclarations'
#Here is where general upkeep scripts are

desc 'validation'
task :validate_printers => :environment do
  
  require 'validation_helper'
  include ValidationHelper
  
  @logfile = File.open("./log/validate_printers.log", 'w+')
  
  assert_all_valid Printer
  
  assert_within_range Printer.all, 'itemheight', 30, 200
  assert_within_range Printer.all, 'itemlength', 30, 100
  assert_within_range Printer.all, 'itemdepth', 20, 100
  
  assert_within_range Printer.all, 'itemweight', 1_000, 30_000
  
  assert_within_range Printer.all, 'listpriceint', 30_00, 12_000_00
  assert_within_range Printer.all, 'price', 30_00, 12_000_00
  
  assert_within_range Printer.all, 'ppm', 30_00, 6_000_00
  assert_within_range Printer.all, 'paperinput', 10, 10_000
  assert_within_range Printer.all, 'resolutionmax', 100, 10_000
  
  @logfile.close
end

desc 'Find duplicates'
task :find_duplicate_printers => :environment do
  
  require 'database_helper'
  include DatabaseHelper
  
  @logfile = File.open("./log/duplicates.log", 'w+')
  duplicate_sets = []
  
  Printer.all.each do |p|
    matches = match_printer_to_printer p, Printer
    
    
    if matches.reject{|x| x.id == p.id}.length > 0
      duplicate_sets << matches.collect{|x| x.id}
      matches.reject{|x| x.id == p.id}.each do |other|
        @logfile.puts "Duplicate for #{p.id}(#{p.model} #{p.brand}): #{other.id} (#{other.model} #{other.brand})"
      end
    end
  end
  
  @logfile.puts "Lists of duplicates:"
  @logfile.puts duplicate_sets.uniq.collect{|x| x * ', '}
  
  puts "Lists of duplicates:"
  puts duplicate_sets.uniq.collect{|x| x * ', '}
  
  @logfile.close
end


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
  env = ENV['RAILS_ENV'] || 'development'
  `lib/c_code/clusteringCodes/codes/hCluster printer ca #{env}`
end

desc "Recluster printers"
task :recluster => [:calculate_factors,:c_clustering] do
  Rake::Task['db:properties'].invoke
end