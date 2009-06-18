class PrintersController < ProductsController
  before_filter :pickProduct
  
  def pickProduct
    session[:productType] = 'Printer'
    s = Session.find(session[:user_id])
    s.update_attribute('product_type', 'Printer') if s.product_type.nil?
  
  end
  
  # Function to calculate the value of ViFi (aka factor) for every feature of every product
  def LookupFactor (productId, fi)
    
  end
  
  def CalculateUtility()
    # For all features
      # Lookup Factor 
      # Multiply by the weight (User's preference)      
  end
  
  def CalculateNewPreferences()
    # CalculateUtility()
    # Run Max Margin algorithm on this cost to obtain new weights/preferences
  end
end
