require 'GlobalDeclarations'
#Here is where general upkeep scripts are

desc "Calculate factors for all features of all products"
task :calculate_factors => :environment do
    # Truncate the existing factors table
    ActiveRecord::Base.connection.execute('TRUNCATE factors')
    $ProdTypeList.each do |pType|
      @dbfeat = {}
      DbFeature.find_all_by_product_type_and_region(pType,"us").each {|f| @dbfeat[f.name] = f}
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
  `lib/c_code/clusteringCodes/codes/hCluster printer`
end

desc "Recluster printers"
task :recluster => [:calculate_factors,:c_clustering] do
  Rake::Task['db:properties'].invoke
end