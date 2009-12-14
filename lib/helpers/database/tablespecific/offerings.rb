#OFFERINGS
#   create_retailer_offering specific_o, product, model=$model
#   update_bestoffer p
#   update_bestoffer_regional p, region
#   make_offering cart, url


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
      pricehistory = [offering.priceUpdate.to_s(:db), offering.priceint].to_yaml
    elsif offering.priceUpdate
      pricehistory = (YAML.load(offering.pricehistory) + [offering.priceUpdate.to_s(:db), \
        offering.priceint]).to_yaml
    else
      pricehistory = nil
    end
    fill_in 'pricehistory', pricehistory, offering
    
    # Update price & timestamp
    fill_in 'priceint', newprice, offering
    fill_in 'priceUpdate', Time.now, offering
  end

end


# Makes a retailer offering from a specific brand's offering.
# Checks if there is already a matching retailer offering via
# the offering_id field and if not, copies over all attributes 
# from the specific brand's offering into a new RetailerOffering
def create_retailer_offering specific_o, product, model=$model
  o  =  find_or_create_offering specific_o, specific_o.attributes
  
  fill_in 'product_type', model.name, o # TODO
  fill_in 'product_id', product.id, o
  
  return o
end

def find_or_create_offering rec, atts
  if rec.offering_id.nil? # If no RetailerOffering is mapped to this brand-specific offering:
    o = create_product_from_atts atts, RetailerOffering
    fill_in 'offering_id', o.id, rec
  else
    o = RetailerOffering.find(rec.offering_id)
    fill_in_all atts, o
  end
  timestamp_offering o
  return o
end