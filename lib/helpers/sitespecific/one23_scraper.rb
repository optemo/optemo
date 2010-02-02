module Scrape123
  
  def clean_refill dirty_atts
    # TODO
  end
  
  # TODO use a different method
  def make_offering_from_atts cart 
    atts = cart.attributes
    web_id = cart.web_id
    url = get_special_url web_id
    if cart.offering_id.nil?
      offer = create_record_from_atts  atts, RetailerOffering
    else
      offer = RetailerOffering.find(cart.offering_id)
    end
    fill_in_all atts, offer
    fill_in 'product_type', 'Cartridge', offer
    fill_in 'toolow', false, offer
    fill_in 'priceUpdate', Time.now, offer
    fill_in 'availabilityUpdate', Time.now, offer
    fill_in 'retailer_id', 16, offer
    fill_in 'offering_id', offer.id, cart
    fill_in 'url', url, offer
    return offer
  end
  
  def special_url web_id
    #TODO For now this is just a regular url.
    base_url = "http://www.123inkjets.com/"
    url = "#{base_url}#{web_id},product.html"
    return url
  end
  
end