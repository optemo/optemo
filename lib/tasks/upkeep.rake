require 'GlobalDeclarations'
#Here is where general upkeep scripts are

desc "Calculate factors for all features of all products"
task :calculate_factors => :environment do
    # Truncate the existing factors table
    ActiveRecord::Base.connection.execute('TRUNCATE factors')
    $ProdTypeList.each do |pType|
      @dbfeat = {}
      DbFeature.find_all_by_product_type(pType).each {|f| @dbfeat[f.name] = f}
      pType.constantize.valid.instock.each do |product|
        newFactorRow = Factor.new
        newFactorRow.product_id = product.id 
        newFactorRow.product_type = pType
        pType.constantize::ContinuousFeatures.each do |f|
          fVal = product.send(f.intern) 
          result = CalculateFactor(fVal, f, @dbfeat[f].max, @dbfeat[f].min)
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

def CalculateFactor (fVal, f, fMax, fMin)  
  # Calculate Denominator value
  denominator = fMax - fMin
  if (denominator == 0)
    return 0
  end  
  # Retrieve the direction value from global variable
  # If direction is Up
  if ($PrefDirection[f] == 1)
    numerator = fVal - fMin
  # If direction is Down
  elsif ($PrefDirection[f] == -1)
    numerator = fMax - fVal
  end
  # Use formula to calculate factor (the factor is a value: v(f))
  factor = numerator/denominator.to_f
  return factor
end