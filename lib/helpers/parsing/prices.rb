module PricesCleaner
  
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
  
  # Figures out all the price attributes
  def clean_prices! atts
    ['salepricestr', 'saleprice', 'listpricestr', 'listprice'].each do |a|
      atts[a] = atts[a].gsub("Less than ",'') if atts[a] # Returns a string stripped of the "less than" part of the price. There is some code somewhere dealing with "too low".  
    end
    s_price_f = get_f((atts['salepricestr'] || atts['saleprice'] || '').strip.gsub(/\*/,'')) 
    l_price_f = get_f((atts['listpricestr'] || atts['listprice'] || '').strip.gsub(/\*/,'')) 
    atts['listpriceint'] = atts['listprice'] = get_price_i( l_price_f) if l_price_f
    atts['salepriceint'] = atts['saleprice'] = get_price_i( s_price_f) if s_price_f
    atts['listpricestr'] = get_price_s( l_price_f) if l_price_f
    atts['salepricestr'] = get_price_s( s_price_f) if s_price_f
    
    price_f = get_f((atts['pricestr'] || atts['price'] || atts['priceint'] || '').strip.gsub(/\*/,'')) 
    atts['priceint'] = atts['price'] = atts['salepriceint'] || atts['listpriceint'] || get_price_i(price_f)
    atts['pricestr'] = atts['salepricestr'] || atts['listpricestr'] || get_price_s(price_f)
    
    return atts
  end
  
end