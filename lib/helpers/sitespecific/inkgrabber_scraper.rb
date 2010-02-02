module InkgrabberScraper
  
  def clean_refill dirty_atts
    clean_atts = cartridge_cleaning_code dirty_atts, 'Ink Grabber', false
    clean_atts['mpn'] = clean_atts['item_number'] if clean_atts['real'] == false  
    clean_atts['yield'] = parse_yield(clean_atts['title']) if clean_atts['yield'].nil?
    clean_atts['toolow'] = false
    clean_atts['retailer_id'] = 18 
    clean_atts['instock'] = clean_atts['stock'] = case dirty_atts['availability'] 
      when "/stock.gif"
        true
      when "/oostock.gif"      
        false
      end
    clean_atts['availability'] = nil
    
    return clean_atts
  end
  
  def special_url url
   special_url = "http://www.jdoqocy.com/click-***REMOVED***-10429337?url="
   special_url += CGI.escape(url)
   return special_url
  end
  
  
  def decently_clean_atts? clean_atts
    model_ok = [clean_atts['model'], clean_atts['mpn']].reject{|x| 
      x.nil?}.collect{|x| likely_cartridge_model_name(x)}.sort.last >= 2
    return (!clean_atts['brand'].nil? and model_ok and clean_atts['toner'] != false)
  end
  
end