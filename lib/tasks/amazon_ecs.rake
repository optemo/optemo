desc "Collect all Camera ASINs for a browse node"
task :get_camera_ASINs => :environment do
  require 'amazon/ecs'
  #Use browse id for Point and Shoot Digital Cameras
  browse_node_id = '330405011'
  search_index = 'Electronics'
  response_group = 'ItemIds'
  Amazon::Ecs.options = {:aWS_access_key_id => '1JATDYR69MNPGRHXPQG2'}
  current_page = 1
  begin
    res = Amazon::Ecs.item_search('',:browse_node => browse_node_id, :search_index => search_index, :response_group => response_group, :item_page => current_page)
    total_pages = res.total_pages unless total_pages
    res.items.each do |item|
      @item = Camera.new
      @item.asin = item.get('asin')
      @item.save!
    end
    current_page += 1
  end while (current_page <= total_pages)
end

desc "Collect all Printer ASINs for a browse node"
task :get_printer_ASINs => :environment do
  require 'amazon/ecs'
  #Use browse id for Laser Printers
  browse_node_id = '172648'
  search_index = 'Electronics'
  response_group = 'ItemIds'
  Amazon::Ecs.options = {:aWS_access_key_id => '1JATDYR69MNPGRHXPQG2'}
  current_page = 1
  begin
    res = Amazon::Ecs.item_search('',:browse_node => browse_node_id, :search_index => search_index, :response_group => response_group, :item_page => current_page)
    total_pages = res.total_pages unless total_pages
    res.items.each do |item|
      @item = Printer.new
      @item.asin = item.get('asin')
      @item.save!
    end
    current_page += 1
  end while (current_page <= total_pages)
end

desc "Get the Camera attributes of a particular ASIN"
task :get_camera_attributes => :environment do
  require 'amazon/ecs'
  asin = ENV["ASIN"]
  if asin.nil? then 
    puts "Please supply an ASIN" 
    Process.exit 
  end
  @camera = Camera.find :first, :conditions => {:asin => asin}
  if @camera == [] then
    puts "ASIN: " + asin + " not found in the database" 
    Process.exit
  end
  Amazon::Ecs.options = {:aWS_access_key_id => '1JATDYR69MNPGRHXPQG2'}
  res = Amazon::Ecs.item_lookup(asin, :response_group => 'ItemAttributes')
  r = res.first_item
  @camera.detailpageurl = r.get('detailpageurl')
  atts = r.search_and_convert('itemattributes')
  @camera.batteriesincluded = atts.get('batteriesincluded')
  @camera.batterydescription = atts.get('batterydescription')
  @camera.binding = atts.get('binding')
  @camera.brand = atts.get('brand')
  @camera.connectivity = atts.get('connectivity')
  @camera.digitalzoom = atts.get('digitalzoom') #in terms of x
  @camera.displaysize = atts.get('displaysize') #in inches
  @camera.ean = atts.get('ean')
  @camera.feature = atts.get_array('feature').join("\n")
  @camera.floppydiskdrivedescription = atts.get('floppydiskdrivedescription')
  @camera.hasredeyereduction = atts.get('hasredeyereduction')
  @camera.includedsoftware = atts.get('includedsoftware')
  @camera.isautographed = atts.get('isautographed')
  @camera.ismemorabilia = atts.get('ismemorabilia')
  @camera.itemheight = atts.get('itemdimensions/height') #hundredths-inches
  @camera.itemlength = atts.get('itemdimensions/length')
  @camera.itemwidth = atts.get('itemdimensions/width')
  @camera.itemweight = atts.get('itemdimensions/weight') #hundredths-pounds
  @camera.label = atts.get('label')
  @camera.listpriceint = atts.get('listprice/amount') #cents
  @camera.listpricestr = atts.get('listprice/formattedprice')
  @camera.manufacturer = atts.get('manufacturer')
  @camera.maximumfocallength = atts.get('maximumfocallength') #mm
  @camera.maximumresolution = atts.get('maximumresolution') #MP
  @camera.minimumfocallength = atts.get('minimumfocallength') #mm
  @camera.model = atts.get('model')
  @camera.mpn = atts.get('mpn')
  @camera.opticalzoom = atts.get('opticalzoom') #in terms of x
  @camera.packageheight = atts.get('packagedimensions/height') #hundredths-inches
  @camera.packagelength = atts.get('packagedimensions/length')
  @camera.packagewidth = atts.get('packagedimensions/width')
  @camera.packageweight = atts.get('packagedimensions/weight') #hundredths-pounds
  @camera.productgroup = atts.get('productgroup')
  @camera.publisher = atts.get('publisher')
  @camera.releasedate = atts.get('releasedate')
  @camera.specialfeatures = atts.get('specialfeatures')
  @camera.studio = atts.get('studio')
  @camera.title = atts.get('title')
  @camera.upc = atts.get('upc')
  
  #Lookup offers/discounts
  res = Amazon::Ecs.item_lookup(asin, :response_group => 'OfferFull')
  r = res.first_item.search_and_convert('offers/offer')
  @camera.merchant = r.get('merchant/merchantid')
  @camera.condition = r.get('offerattributes/condition')
  @camera.salepriceint = r.get('offerlisting/price/amount')
  @camera.salepricestr = r.get('offerlisting/price/formattedprice')
  @camera.iseligibleforsupersavershipping = r.get('offerlisting/iseligibleforsupersavershipping')
  
  #Lookup images
  res = Amazon::Ecs.item_lookup(asin, :response_group => 'Images')
  r = res.first_item
  @camera.imagesurl = r.get('smallimage/url')
  @camera.imagesheight = r.get('smallimage/height')
  @camera.imageswidth = r.get('smallimage/width')
  @camera.imagemurl = r.get('mediumimage/url')
  @camera.imagemheight = r.get('mediumimage/height')
  @camera.imagemwidth = r.get('mediumimage/width')
  @camera.imagelurl = r.get('largeimage/url')
  @camera.imagelheight = r.get('largeimage/height')
  @camera.imagelwidth = r.get('largeimage/width')
  @camera.save!
end

desc "Get all the Amazon data for the current Camera ASINs"
task :get_camera_data_for_ASINs => :environment do
  Camera.find(:all).each do |camera|
    if !camera.asin.blank?
      system "rake get_camera_attributes ASIN=#{camera.asin} --trace"  
    end
  end
end

desc "Get all the Amazon data for the current Printer ASINs"
task :get_printer_data_for_ASINs => :environment do
  require 'amazon/ecs'
  Printer.find(:all).each do |p|
    if !p.asin.blank?
      puts 'Processing' + p.asin
      Amazon::Ecs.options = {:aWS_access_key_id => '1JATDYR69MNPGRHXPQG2'}
      res = Amazon::Ecs.item_lookup(p.asin, :response_group => 'ItemAttributes')
      r = res.first_item
      unless r.nil?
      p.detailpageurl = r.get('detailpageurl')
      atts = r.search_and_convert('itemattributes')
      p.binding = atts.get('binding')
      p.brand = atts.get('brand')
      p.color = atts.get('color')
      p.cpumanufacturer = atts.get('cpumanufacturer')
      p.cpuspeed = atts.get('cpuspeed')
      p.cputype = atts.get('cputype')
      p.displaysize = atts.get('displaysize') #in inches
      p.ean = atts.get('ean')
      p.feature = atts.get_array('feature').join("\n")
      p.graphicsmemorysize = atts.get('graphicsmemorysize') #in MB
      p.isautographed = atts.get('isautographed')
      p.ismemorabilia = atts.get('ismemorabilia')
      p.itemheight = atts.get('itemdimensions/height') #hundredths-inches
      p.itemlength = atts.get('itemdimensions/length')
      p.itemwidth = atts.get('itemdimensions/width')
      p.itemweight = atts.get('itemdimensions/weight') #hundredths-pounds
      p.label = atts.get('label')
      p.language = atts.get('languages/language/name')
      p.legaldisclaimer = atts.get('legaldisclaimer')
      p.listpriceint = atts.get('listprice/amount') #cents
      p.listpricestr = atts.get('listprice/formattedprice')
      p.manufacturer = atts.get('manufacturer')
      p.model = atts.get('model')
      p.modemdescription = atts.get('modemdescription')
      p.mpn = atts.get('mpn')
      p.nativeresolution = atts.get('nativeresolution')
      p.numberofitems = atts.get('numberofitems')
      p.packageheight = atts.get('packagedimensions/height') #hundredths-inches
      p.packagelength = atts.get('packagedimensions/length')
      p.packagewidth = atts.get('packagedimensions/width')
      p.packageweight = atts.get('packagedimensions/weight') #hundredths-pounds
      p.processorcount = atts.get('processorcount')
      p.productgroup = atts.get('productgroup')
      p.publisher = atts.get('publisher')
      p.specialfeatures = atts.get('specialfeatures')
      p.studio = atts.get('studio')
      p.systemmemorysize = atts.get('systemmemorysize')
      p.systemmemorytype = atts.get('systemmemorytype')
      p.title = atts.get('title')
      p.upc = atts.get('upc')
      p.warranty = atts.get('warranty')

      #Find lowest new price
      #res = Amazon::Ecs.item_lookup(asin, :response_group => 'OfferSummary', :condition => 'New', :merchant_id => 'All')
      #lowprice = res.first_item.get('offersummary/lowestnewprice/amount')
      lowestprice = 100000000
      lowmerchant = ''
      current_page = 1
      begin
        res = Amazon::Ecs.item_lookup(p.asin, :response_group => 'OfferListings', :condition => 'New', :merchant_id => 'All', :offer_page => current_page)
        total_pages = res.total_pages unless total_pages
        offers = res.first_item.search_and_convert('offers/offer')
        if offers.nil?
          current_page += 1
          next
        end
        offers = [] << offers unless offers.class == Array
        offers.each {|o| 
          pricestr = o.get('offerlisting/price/amount')
          if pricestr == 'Too low to display'
            p.toolow = true
            current_page += 1
            next
          end
          priceint = pricestr.to_i
          if priceint < lowestprice
            lowestprice = priceint
            lowmerchant = o.get('merchant/merchantid')
          end
        }
        #offers.reject! {|o| o.nil? || lowprice != o.get('offerlisting/price/amount')}
        current_page += 1
      end while (current_page <= total_pages)
      
      #Save lowest price
      if !lowmerchant.blank?
        res = Amazon::Ecs.item_lookup(p.asin, :response_group => 'OfferListings', :condition => 'New', :merchant_id => lowmerchant)
        offers = res.first_item
        if !offers.nil?
          p.merchantid = offers.get('merchant/merchantid')
          p.merchantname = offers.get('merchant/merchantname')
          p.salepriceint = offers.get('offerlisting/price/amount')
          p.salepricestr = offers.get('offerlisting/price/formattedprice')
          p.availability = offers.get('offerlisting/availability')
          p.iseligibleforsupersavershipping = offers.get('offerlisting/iseligibleforsupersavershipping')
        end
      end

      #Lookup images
      res = Amazon::Ecs.item_lookup(p.asin, :response_group => 'Images')
      r = res.first_item
      p.imagesurl = r.get('smallimage/url')
      p.imagesheight = r.get('smallimage/height')
      p.imageswidth = r.get('smallimage/width')
      p.imagemurl = r.get('mediumimage/url')
      p.imagemheight = r.get('mediumimage/height')
      p.imagemwidth = r.get('mediumimage/width')
      p.imagelurl = r.get('largeimage/url')
      p.imagelheight = r.get('largeimage/height')
      p.imagelwidth = r.get('largeimage/width')
      p.save!
      end
    end
  end
end

desc "Scraping Amazon Hidden Price"
task :scrape_hidden_price => :environment do
  require 'open-uri'
  require 'hpricot'
  #Printer.find(:all, :conditions => 'salepricestr="Too low to display" or salepricestr is null').each {|p|
  Printer.find_by_toolow('true').each {|p|
  url = "http://www.amazon.com/o/asin/#{p.asin}"
  doc = Hpricot(open(url,{"User-Agent" => "User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1"}).read)
  price = (doc/"b[@class='priceLarge']").first
  if !price.nil?
    priceint = price.innerHTML.gsub(/\D/,'').to_i
    if !p.blank? && priceint < p.salepriceint
    p.salepricestr = price.innerHTML
    p.salepriceint = priceint
    p.merchantid = 'ATVPDKIKX0DER' unless p.merchantid
    p.save!
  end
}
#    extractor = Scrubyt::Extractor.define do
#   fetch 'http://www.amazon.com/gp/product/B000UZH526/ref=olp_product_details?ie=UTF8&me=&seller='
#  # click_link brand  
#      
#      price "HP LaserJet P1006 Printer", :generalize => true, :write_text => true
#     #next_page "Next", :limit => 2                    
#   end
#   puts extractor.to_xml

end