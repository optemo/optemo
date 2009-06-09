require 'bestbuy_ecs'
$PRODUCT_TYPE = 'Printer'
$RETAILER = 'BestBuy'
desc "Download BestBuy data with Remix"
task :remix_BestBuy => :environment do
  e = BestBuy::Ecs.new
  r = e.product_search({:category => 'Laser*'})
  puts "Total resuts: "+r.total_results.to_s
  downloadResults(r)
end

def downloadResults(r)
  loop do
    r.items.each do |i|
      h = i.get_hash
      h.delete(:"\n")
      h[:bb_class] = h.delete(:class) #reserved ruby functions
      h[:bb_new] = h.delete(:new)
      if m = matchPrinter(h)
        productOffering(m,h)
        h[:printer_id] = m
      end
      p = BestBuyPrinter.new(h)
      p.save
    end
    sleep(0.2) # 5 reqs / sec
    break if (r = r.next_results).nil?
  end
end

def productOffering(product_id,h)
  retailer_id = Retailer.find_by_name($RETAILER).id
  o = RetailerOffering.find_by_product_id_and_product_type_and_retailer_id(product_id,$PRODUCT_TYPE,retailer_id)
  if o.nil?
    o = RetailerOffering.new
    o.product_id = product_id
    o.product_type = $PRODUCT_TYPE
    o.retailer_id = retailer_id
  elsif o.priceint != (h[:salePrice].to_f*100).to_i
    #Save old prices only if price has changed
    if o.pricehistory.nil?
      o.pricehistory = [o.priceUpdate.to_s(:db), o.priceint].to_yaml
    else
      o.pricehistory = (YAML.load(o.pricehistory) + [o.priceUpdate.to_s(:db), o.priceint]).to_yaml
    end
  end
  o.active = h[:active]
  o.activeUpdate = h[:activeUpdateDate]
  o.stock = h[:onlineAvailability]
  o.availability = h[:onlineAvailabilityText]
  o.availabilityUpdate h[:onlineAvailabilityUpdateDate]
  o.pricestr = '$' + h[:salePrice].to_s
  o.priceint = (h[:salePrice].to_f*100).to_i
  o.priceUpdate = h[:priceUpdateDate]
  o.shippingCost = h[:shippingCost]
  o.freeShipping = h[:freeShipping]
  o.url = h[:cjAffiliateUrl]
  o.save
end

def matchPrinter(h)
  product = Printer.find_by_model(h[:modelNumber])
  return product.id unless product.nil? #Easy, match by model
  match = nil
  Printer.all.each do |printer|
    if printer.model && printer.model.index(h[:modelNumber])
      if match.nil?
        match = printer
      else
        raise StandardException "Double match: #{printer.id} with #{match.id} for #{h[:sku]}"
      end
    end
  end
  match.id unless match.nil?
end