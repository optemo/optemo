module OfferingsHelper
  require 'yaml'

  def timestamp_offering ro
    parse_and_set_attribute('availabilityUpdate', Time.now, ro)
    parse_and_set_attribute('priceUpdate', Time.now, ro)
    ro
  end
  
  # Does record_updated_price and copies 
  # over other offering attributes as well.
  def update_offering(newparams, offering)
    newprice = newparams['priceint']
    record_updated_price(newprice, offering) if newprice
    newparams.each{|name,val| parse_and_set_attribute(name, val, offering)}
    offering
  end
  
  # Records a new price for the given offering
  # if the price has changed. Also puts a time
  # stamp (priceUpdate) and puts the latest thing
  # in the price history.
  def record_updated_price(newprice, offering)
    if offering.priceint.to_s != newprice.to_s # Save old prices only if price has changed
      
      # Write the old price down in the history
      if offering.pricehistory.nil? and offering.priceUpdate
        pricehist_obj = {offering.priceUpdate.to_s(:db) => (offering.priceint || 0)}
        pricehistory = YAML::dump(pricehist_obj)
      elsif offering.priceUpdate
        hist_hash = {}
        begin
          hist_hash = YAML::load(offering.pricehistory)
        rescue Exception => e
          report_error "Price history was : #{offering.pricehistory} for RO #{offering.id}"
          begin
            hist_hash = YAML::load("#{offering.pricehistory}\n")
          rescue Exception => e
            report_error "Newline did not help"
          end
        end
        hist_hash = {} if hist_hash.class.name != 'Hash'
        hist_hash[offering.priceUpdate.to_s(:db)] = (offering.priceint || 0) 
        pricehistory = YAML::dump(hist_hash)
      else
        pricehistory = nil
      end
      #debugger if pricehistory.match(/\n$/).nil?
      parse_and_set_attribute('pricehistory', pricehistory, offering)
      
      # Update price & timestamp
      parse_and_set_attribute('priceint', newprice, offering)
      parse_and_set_attribute('priceUpdate', Time.now, offering)
    end
    offering
  end
  
  # Updates best offer for all regions
  def update_bestoffer(product)
    # Region suffixes, used internally in the database format.
    {'US' => ''}.each_pair do |region, regioncode|  # This used to have the pair: 'CA' => '_ca' in it. No Canadian pricing for now
      # Finds the best offer by region and records the new
      # bestoffer price and product id.
      matching_ro = RetailerOffering.find(:all, :conditions => ["product_id=? and product_type=?", product.id, Session.current.product_type]).reject{ |x| !x.stock or x.priceint.nil? }
      if matching_ro.empty?
        parse_and_set_attribute("instock#{regioncode}", false, product)
        return product
      end
      # This is a problem: null prices. The product should not have a null price when it gets here maybe?
      lowest = matching_ro.sort{|x,y| x.priceint <=> y.priceint }.first

      # Should probably just set it once and then add '_ca', the region suffix, to the end of each.
      regional = {'price'=>'price', 'pricestr' => 'pricestr', 'bestoffer' => 'bestoffer', 'prefix' => '', 'instock'=> 'instock'}
      # The new database format does not contain most of these fields.
#      parse_and_set_attribute(regional['bestoffer'], lowest.id, product)
#      parse_and_set_attribute(regional['pricestr'], lowest.pricestr, product)
      # We need to update the price ContSpec record here
      price_record = ContSpec.find_by_name_and_product_id("price", product.id)
      price_record = ContSpec.new({:product_id => product.id, :name => "price", :product_type => Session.current.product_type}) if price_record.nil?
      parse_and_set_attribute('value', (lowest.priceint.to_f / 100.0), price_record)
      price_record.save
      parse_and_set_attribute('instock', true, product)
    end
    product
  end
end