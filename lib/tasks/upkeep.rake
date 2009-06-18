require 'GlobalDeclarations'
#Here is where general upkeep scripts are

desc "Calculate factors for all features of all products"
task :calculate_factors => :environment do
    ['Printer','Camera'].each do |pType|
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

def CalculateFactor (fVal, f, fMax, fMin)  #productId                       # productId should be changed to fVal
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