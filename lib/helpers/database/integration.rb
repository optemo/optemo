module IntegrationHelper
  
  # Picks the most reliable value based on several answers
  def vote(array)
     count_votes = array.inject({}){ |r,x| r.merge( x=>(1+(r[x]||0))) }
     return nil if count_votes.length == 0
     winner = count_votes.to_a.sort{|x,y| y[1]<=>x[1]}.first[0]
     return winner
  end
   
   # Averages everything in the array
  def mean(array)
     return array.inject(0){ |r,x| r + x.to_f }/array.size.to_f
  end
  
  # Links RetailerOffering to ScrapedProduct
  def link_ro_and_sp ro, sp
    local_id = ro.local_id || sp.local_id
    retailer_id = ro.retailer_id || sp.retailer_id
    if local_id.nil? or retailer_id.nil?
      report_error "Couldn't link RO #{ro.id} and SP #{sp.id}"
      return false 
    end
    [ro,sp].each do |x| 
      parse_and_set_attribute('local_id', local_id, x)
      parse_and_set_attribute('retailer_id', retailer_id, x)
      x.save
    end
    return true
  end
  
  # Finds all RetailerOfferings linked to ScrapedProduct
  def find_ros_from_scraped local_id, retailer_id
    ros = RetailerOffering.find_all_by_local_id_and_retailer_id(local_id, retailer_id)
    return ros.reject{|x| x.product_type != $product_type}
  end
  
end
