class PrintersController < ProductsController
  before_filter :pickProduct
  
  def pickProduct
    session[:productType] = 'Printer'
    s = Session.find(session[:user_id])
    s.update_attribute('product_type', 'Printer') if s.product_type.nil?
  
  end
  
  # Function to calculate the value of ViFi (aka factor) for every feature of every product
  def CalculateFactor (productId, fi)
    # productId: The id of the product
    # fi: The feature

    prod = session[:productType].constantize.find(productId)
    # ToDo:
    # Retrieve value of feature for that product    
    # fVal = value of feature fi for product
    fVal = prod.send(fi)
    
    # ToDo:
    # Calculate the min value for that feature across all products
    fMin = @dbfeat[fi].min
    
    # ToDo:
    # Calculate the max value for that feature across all products
    fMax = @dbfeat[fi].max

    # Calculate Denominator value
    denominator = fMax - fMin
        
    # Retrieve the direction value from global variable
    # If direction is Up
    if ($PrefDirection[fi] == 1)
      # Use formula to calculate factor (value)
      numerator = fVal - fMin
    # If direction is Down
    elsif ($PrefDirection[fi] == -1)
      numerator = fMax - fVal
    end
    
    # Use formula to calculate factor (the factor is a value: v(f))
    factor = numerator/denominator.to_f
    return factor
  end
  
  def CalculateUtility()
    # For all features
      # Calculate Factor 
      # Multiply by the weight (User's preference)      
  end
  
  def CalculateNewPreferences()
    # CalculateUtility()
    # Run Max Margin algorithm on this cost to obtain new weights/preferences
  end
end
