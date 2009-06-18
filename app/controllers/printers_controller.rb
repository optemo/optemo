class PrintersController < ProductsController
  before_filter :pickProduct
  
  def pickProduct
    session[:productType] = 'Printer'
    s = Session.find(session[:user_id])
    s.update_attribute('product_type', 'Printer') if s.product_type.nil?
  
  end
  
  def CalculateFactor(pi, fi)
    # pi: The product
    # fi: The feature
    # Retrieve the direction value from global variable
    # If direction is Up
      # Use formula to calculate factor (value)
    # If direction is Down
      # Use formula to calculate factor (the factor is a value: v(f))
    #
  end
  
  def CalculateCost()
    # For all features
      # Calculate Factor 
      # Multiply by the weight (User's preference)      
  end
  
  def CalculateNewPreferences()
    # CalculateCost()
    # Run Max Margin algorithm on this cost to obtain new weights/preferences
  end
end
