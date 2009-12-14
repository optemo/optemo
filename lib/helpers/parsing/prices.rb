#PRICES CLEANING
#   clean_prices atts

module PricesHelper
  
  # Returns the price integer: float * 100, rounded
  def get_price_i price_f
    return nil if price_f.nil? 
    return (price_f * 100).round
  end
  
  # Returns the price string
  def get_price_s price_f
    return nil if price_f.nil? 
    return (format "$%.2f", price_f)
  end
  
end