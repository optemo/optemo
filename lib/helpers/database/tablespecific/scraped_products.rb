module ScrapedProductsHelper
  
  # Gets Scraped Printer entries by a list of 
  # matching retailer ids, where none of the SPs
  # are matched to a Printer.
  def scraped_by_retailers retailer_ids, scrapedmodel=$scrapedmodel, unmatched_only=true
     sps = []
     retailer_ids.each do |ret|
       if unmatched_only
         sps = sps | scrapedmodel.find_all_by_retailer_id_and_product_id(ret,nil)
       else
         sps = sps | scrapedmodel.find_all_by_retailer_id(ret)
       end
     end
     return sps
  end
  
  def find_or_create_scraped_product(atts) 
      rid = atts['retailer_id']
      lid = atts['local_id']
      return nil if rid.nil? or lid.nil?
      sp = $scrapedmodel.find_by_retailer_id_and_local_id(rid,lid)
      if sp.nil?
        sp = $scrapedmodel.new(atts.reject{|k,v| not ($scrapedmodel.column_names.include?(k))})
      else
        atts.each{|name,val| parse_and_set_attribute(name, val, sp)}
      end
      sp.save
      return sp
  end
  
  #def find_sp local_id, retailer_id
  #  return ScrapedPrinter.find_all_by_local_id_and_retailer_id(local_id, retailer_id).first
  #end
end