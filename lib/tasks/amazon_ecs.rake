desc "Collect all the ASINs for a browse node"
task :get_ASINs => :environment do
  require 'amazon/ecs'
  #Use browse id for Point and Shoot Digital Cameras
  browse_node_id = '330405011'
  search_index = 'Electronics'
  response_group = 'ItemIds'
  Amazon::Ecs.options = {:aWS_access_key_id => '1JATDYR69MNPGRHXPQG2'}
  current_page = 1
  begin
    res = Amazon::Ecs.item_search('',:browse_node => browse_node_id, :search_index => search_index, :response_group => response_group, :item_page => current_page)
    @total_pages = res.total_pages unless @total_pages
    res.items.each do |item|
      @camera = Camera.new
      @camera.asin = item.get('asin')
      @camera.save!
    end
    current_page += 1
  end while (current_page <= @total_pages)
end

desc "Get the attributes of a particular ASIN"
task :get_attributes => :environment do
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

desc "Get all the Amazon data for the current ASINs"
task :get_amazon_data_for_ASINs => :environment do
  Camera.find(:all).each do |camera|
    if !camera.asin.blank?
      system "rake get_attributes ASIN=#{camera.asin} --trace"  
    end
  end
  
end