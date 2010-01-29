module OfferingsHelper
  require 'yaml'

  def timestamp_offering ro
    fill_in 'availabilityUpdate', Time.now, ro
    fill_in 'priceUpdate', Time.now, ro
    return ro
  end
  
  # Does record_updated_price and copies 
  # over other offering attributes as well.
  def update_offering newparams, offering
    newprice = newparams['priceint']
    record_updated_price newprice, offering if newprice
    fill_in_all newparams, offering
  end
  
  # Records a new price for the given offering
  # if the price has changed. Also puts a time
  # stamp (priceUpdate) and puts the latest thing
  # in the price history.
  def record_updated_price newprice, offering
    if offering.priceint.to_s != newprice.to_s # Save old prices only if price has changed
      
      # Write the old price down in the history
      if offering.pricehistory.nil? and offering.priceUpdate
        pricehist_obj = {offering.priceUpdate.to_s(:db) => (offering.priceint || 0)}
        pricehistory = YAML::dump(pricehist_obj)
      elsif offering.priceUpdate
        hist_hash = YAML::load(offering.pricehistory)
        hist_hash[offering.priceUpdate.to_s(:db)] = (offering.priceint || 0) 
        pricehistory = YAML::dump(hist_hash)
      else
        pricehistory = nil
      end
      #debugger if pricehistory.match(/\n$/).nil?
      fill_in('pricehistory', pricehistory, offering)
      
      # Update price & timestamp
      fill_in 'priceint', newprice, offering
      fill_in 'priceUpdate', Time.now, offering
    end
  
  end
  
  def find_or_create_offering rec, atts
  # TODO phase out this method
    return nil
    #if rec.offering_id.nil? # If no RetailerOffering is mapped to this brand-specific offering:
    #  return nil if (atts['price']||0) > 20_000_00
    #  o = create_record_from_atts atts, RetailerOffering
    #  fill_in 'offering_id', o.id, rec
    #else
    #  o = RetailerOffering.find(rec.offering_id)
    #  fill_in_all atts, o unless (atts['price']||0) > 20_000_00
    #end
    #timestamp_offering o
    #return o
  end
  
  # Updates best offer for all regions
  def update_bestoffer p
    $region_suffixes.keys.each do |region|
      update_bestoffer_regional p, region
    end
    
  end
  
  # Finds the best offer by region and records the new
  # bestoffer price and product id.
  def update_bestoffer_regional p, region
    matching_ro = RetailerOffering.find(:all, :conditions => \
      "product_id LIKE #{p.id} and product_type LIKE '#{$model.name}' and region LIKE '#{region}'").\
      reject{ |x| !x.stock or x.priceint.nil? }
    if matching_ro.empty?
      fill_in "instock#{$region_suffixes[region]}", false, p
      return
    end
    
    lowest = matching_ro.sort{ |x,y|
      x.priceint <=> y.priceint
    }.first
    
    regional = case region 
      when 'CA' then $ca
      when 'US' then $us
      else []
    end
    fill_in regional['bestoffer'], lowest.id, p
    fill_in regional['price'], lowest.priceint, p
    fill_in regional['pricestr'], "#{regional['prefix']}#{lowest.pricestr}", p
    fill_in regional['instock'], true, p
  end
end