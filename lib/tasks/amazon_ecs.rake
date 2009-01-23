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

desc "Get the Printer attributes of a particular ASIN"
task :get_printer_attributes => :environment do
  require 'amazon/ecs'
  asin = ENV["ASIN"]
  if asin.nil? then 
    puts "Please supply an ASIN" 
    Process.exit 
  end
  @printer = Printer.find :first, :conditions => {:asin => asin}
  if @printer == [] then
    puts "ASIN: " + asin + " not found in the database" 
    Process.exit
  end
  Amazon::Ecs.options = {:aWS_access_key_id => '1JATDYR69MNPGRHXPQG2'}
  res = Amazon::Ecs.item_lookup(asin, :response_group => 'ItemAttributes')
  r = res.first_item
  @printer.detailpageurl = r.get('detailpageurl')
  atts = r.search_and_convert('itemattributes')
  @printer.binding = atts.get('binding')
  @printer.brand = atts.get('brand')
  @printer.color = atts.get('color')
  @printer.cpumanufacturer = atts.get('cpumanufacturer')
  @printer.cpuspeed = atts.get('cpuspeed')
  @printer.cputype = atts.get('cputype')
  @printer.displaysize = atts.get('displaysize') #in inches
  @printer.ean = atts.get('ean')
  @printer.feature = atts.get_array('feature').join("\n")
  @printer.graphicsmemorysize = atts.get('graphicsmemorysize') #in MB
  @printer.isautographed = atts.get('isautographed')
  @printer.ismemorabilia = atts.get('ismemorabilia')
  @printer.itemheight = atts.get('itemdimensions/height') #hundredths-inches
  @printer.itemlength = atts.get('itemdimensions/length')
  @printer.itemwidth = atts.get('itemdimensions/width')
  @printer.itemweight = atts.get('itemdimensions/weight') #hundredths-pounds
  @printer.label = atts.get('label')
  @printer.language = atts.get('languages/language/name')
  @printer.legaldisclaimer = atts.get('legaldisclaimer')
  @printer.listpriceint = atts.get('listprice/amount') #cents
  @printer.listpricestr = atts.get('listprice/formattedprice')
  @printer.manufacturer = atts.get('manufacturer')
  @printer.model = atts.get('model')
  @printer.modemdescription = atts.get('modemdescription')
  @printer.mpn = atts.get('mpn')
  @printer.nativeresolution = atts.get('nativeresolution')
  @printer.numberofitems = atts.get('numberofitems')
  @printer.packageheight = atts.get('packagedimensions/height') #hundredths-inches
  @printer.packagelength = atts.get('packagedimensions/length')
  @printer.packagewidth = atts.get('packagedimensions/width')
  @printer.packageweight = atts.get('packagedimensions/weight') #hundredths-pounds
  @printer.processorcount = atts.get('processorcount')
  @printer.productgroup = atts.get('productgroup')
  @printer.publisher = atts.get('publisher')
  @printer.specialfeatures = atts.get('specialfeatures')
  @printer.studio = atts.get('studio')
  @printer.systemmemorysize = atts.get('systemmemorysize')
  @printer.systemmemorytype = atts.get('systemmemorytype')
  @printer.title = atts.get('title')
  @printer.upc = atts.get('upc')
  @printer.warranty = atts.get('warranty')
  
  #Find lowest new price
  res = Amazon::Ecs.item_lookup(asin, :response_group => 'OfferSummary', :condition => 'New', :merchant_id => 'All')
  lowprice = res.first_item.get('offersummary/lowestnewprice/amount')
  current_page = 1
  begin
    res = Amazon::Ecs.item_lookup(asin, :response_group => 'OfferListings', :condition => 'New', :merchant_id => 'All', :offer_page => current_page)
    total_pages = res.total_pages unless total_pages
    offers = res.first_item.search_and_convert('offers/offer')
    offers = [] << offers unless offers.class == Array
    offers.reject! {|o| o.nil? || lowprice != o.get('offerlisting/price/amount')}
    if !offers.empty?
      @printer.merchantid = offers.first.get('merchant/merchantid')
      @printer.merchantname = offers.first.get('merchant/merchantname')
      @printer.salepriceint = offers.first.get('offerlisting/price/amount')
      @printer.salepricestr = offers.first.get('offerlisting/price/formattedprice')
      @printer.availability = offers.first.get('offerlisting/availability')
      @printer.iseligibleforsupersavershipping = offers.first.get('offerlisting/iseligibleforsupersavershipping')
    end
    current_page += 1
  end while (current_page <= total_pages)
  
  
  #Lookup images
  res = Amazon::Ecs.item_lookup(asin, :response_group => 'Images')
  r = res.first_item
  @printer.imagesurl = r.get('smallimage/url')
  @printer.imagesheight = r.get('smallimage/height')
  @printer.imageswidth = r.get('smallimage/width')
  @printer.imagemurl = r.get('mediumimage/url')
  @printer.imagemheight = r.get('mediumimage/height')
  @printer.imagemwidth = r.get('mediumimage/width')
  @printer.imagelurl = r.get('largeimage/url')
  @printer.imagelheight = r.get('largeimage/height')
  @printer.imagelwidth = r.get('largeimage/width')
  @printer.save!
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
  Printer.find(:all).each do |p|
    if !p.asin.blank?
      system "rake get_printer_attributes ASIN=#{p.asin} --trace"  
    end
  end
end