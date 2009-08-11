module Amazon
  
  def interpret_special_features(p)
    sf = p.specialfeatures
    a = sf[3..-1].split('|') #Remove leading nv:
    features = {}
    a.map{|l| 
      c = l.split('^') 
      features[c[0]] = c[1]
    }
    p.ppm = features['Print Speed'].match(/\d+[.]?\d*/)[0] if features['Print Speed']
    p.ttp = features['First Page Output Time'].match(/\d+[.]?\d*/)[0] if features['First Page Output Time'] && features['First Page Output Time'].match(/\d+[.]?\d*/)
    if features['Resolution']
      tmp = features['Resolution'].match(/(\d,\d{3}|\d+) ?x?X? ?(\d,\d{3}|\d+)?/)[1,2].compact
      tmp*=2 if tmp.size == 1
      p.resolution = tmp.sort{|a,b| 
        a.gsub!(',','')
        b.gsub!(',','')
        a.to_i < b.to_i ? 1 : a.to_i > b.to_i ? -1 : 0
      }.join(' x ') 
      p.resolutionmax = p.resolution.split(' x ')[0]
    end # String drop down style
    p.duplex = features['Duplex Printing'] # String
    p.connectivity = features['Connectivity'] # String
    p.papersize = features['Paper Sizes Supported'] # String
    p.paperoutput = features['Standard Paper Output'].match(/(\d,\d{3}|\d+)/)[0] if features['Standard Paper Output'] #Numeric
    p.dimensions = features['Dimensions'] #Not parsed yet
    p.dutycycle = features['Maximum Duty Cycle'].match(/(\d{1,3}(,\d{3})+|\d+)/)[0].gsub(',','') if features['Maximum Duty Cycle']
    p.paperinput = features['Standard Paper Input'].match(/(\d,\d{3}|\d+)/)[0] if features['Standard Paper Input'] && features['Standard Paper Input'].match(/(\d,\d{3}|\d+)/) #Numeric
    #Parse out special features
    if !features['Special Features'].nil?
      if features['Special Features'] == "Duplex Printing"
        features['Special Features'] = nil
        p.duplex = "Yes" if p.duplex.nil?
      end
    end
    p.special = features['Special Features']
    p
  end

  def findprice(p, region)
    region ||= "us" #Default region is US
    #Find the lowest price
    highestprice = 1000000000
    merchants = case region
      when "us"
        ["Amazon", "Amazon Marketplace"]
      when "ca"
        ["Amazon.ca", "Amazon.ca Marketplace"]
    end
    lowestprice = Hash[*merchants.zip([highestprice]*merchants.size).flatten]
    lowmerchant = Hash[*merchants.zip(['']*merchants.size).flatten]
    lowestentry = Hash[*merchants.zip([nil]*merchants.size).flatten]
    current_page = 1
    $amazonmodel.find_all_by_product_id(p.id).each do |e|
      begin
        sleep(2) #Be nice
        res = Amazon::Ecs.item_lookup(e.asin, :response_group => 'OfferListings', :condition => 'New', :merchant_id => 'All', :offer_page => current_page, :country => region.intern)
        total_pages = res.total_pages unless total_pages
        if res.first_item.nil?
          current_page += 1
          next
        end
        offers = res.first_item.search_and_convert('offers/offer')
        if offers.nil?
          current_page += 1
          next
        end
        offers = [] << offers unless offers.class == Array
        offers.each do |o| 
          price = o.get('offerlisting/price/amount').to_i
          merchantid = o.get('merchant/merchantid')
          merchant = case merchantid 
            when AmazonID 
              "Amazon"
            when AmazonCAID
              "Amazon.ca"
            else
              case region
              when "us"
                "Amazon Marketplace"
              when "ca"
                "Amazon.ca Marketplace"
              end
          end
          if price < lowestprice[merchant]
            lowestprice[merchant] = price
            lowestentry[merchant] = e
            lowmerchant[merchant] = merchantid
          end
        end
        current_page += 1
        sleep(2) #One Req per sec
      end while (current_page <= total_pages)
    end
    sleep(1) #Be Nice
    #Save lowest prices
    merchants.each do |merchant|
      if lowmerchant[merchant].blank?
        offer = RetailerOffering.find_by_product_id_and_product_type_and_retailer_id_and_region(p.id,p.class.name,Retailer.find_by_name(merchant).id,region)
        offer.update_attributes({:stock => false, :toolow => false}) unless offer.nil?
      else
        saveoffer(lowestentry[merchant],Retailer.find_by_name_and_region(merchant,region).id,lowmerchant[merchant],region)
        sleep(2) #One Req per sec
      end
    end

    #Find lowest product price
    os = RetailerOffering.find_all_by_product_id_and_product_type_and_region(p.id,p.class.name,region)
    lowest = highestprice
    case region
    when "ca"
      p.instock_ca = false
    else
      p.instock = false
    end
    if !os.nil? && !os.empty?
      os.each do |o| 
        if o.stock && o.priceint && o.priceint < lowest
          lowest = o.priceint
          case region
          when "ca"
            p.price_ca = lowest
            p.price_ca_str = o.pricestr
            p.instock_ca = true
          else
            p.price = lowest
            p.pricestr = o.pricestr
            p.instock = true
          end
          p.bestoffer = o.id
        end
      end
    end
    p
  end

  def saveoffer(p,retailer,merchant,region)
    puts [p.product_id,Retailer.find(retailer).name,merchant,region].join(' ')
    begin
      res = Amazon::Ecs.item_lookup(p.asin, :response_group => 'OfferListings', :condition => 'New', :merchant_id => merchant, :country => region.intern)
    rescue Exception => exc
      puts "Error: #{exc.message} for product #{p.asin} and merchant #{merchant} in region #{region}"
      sleep(30)
      saveoffer(p,retailer,merchant,region)
      return
    end
    offer = res.first_item
    #Look for old Retail Offering
    unless offer.nil?
      o = RetailerOffering.find_by_product_id_and_product_type_and_retailer_id_and_region(p.product_id,$model.name,retailer,region)
      if o.nil?
        o = RetailerOffering.new
        o.product_id = p.product_id
        o.product_type = $model.name
        o.retailer_id = retailer
        o.region = region
      elsif o.priceint != offer.get('offerlisting/price/amount')
        #Save old prices only if price has changed
        if o.pricehistory.nil?
          o.pricehistory = [o.priceUpdate.to_s(:db), o.priceint].to_yaml if o.priceUpdate
        else
          o.pricehistory = (YAML.load(o.pricehistory) + [o.priceUpdate.to_s(:db), o.priceint]).to_yaml if o.priceUpdate
        end
      end
      #Too Low to Display
      if offer.get('offerlisting/price/formattedprice') == 'Too low to display'
        o.toolow = true
        o.priceint = scrape_hidden_prices(p,region)
        o.pricestr = "#{'CDN' if region == 'ca'}$" + (o.priceint.to_f/100).to_s
      else
        o.toolow = false
        o.priceint = offer.get('offerlisting/price/amount')
        o.pricestr = offer.get('offerlisting/price/formattedprice')
      end
      o.stock = true
      o.availability = offer.get('offerlisting/availability')
      o.iseligibleforsupersavershipping = offer.get('offerlisting/iseligibleforsupersavershipping')
      o.merchant = merchant
      o.url = "http://amazon.#{region=="us" ? "com" : region}/gp/product/"+p.asin+"?tag=#{region=="us" ? "optemo-20" : "laserprinterh-20"}&m="+merchant
      o.priceUpdate = Time.now.to_s(:db)
      o.save
    end
  end

  def scrape_hidden_prices(p,region)
    require 'open-uri'
    require 'hpricot'
    url = "http://www.amazon.#{region=="us" ? "com" : region}/o/asin/#{p.asin}"
    doc = Hpricot(open(url,{"User-Agent" => "User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1"}).read)
    price = (doc/"b[@class='priceLarge']").first
    priceint = price.innerHTML.gsub(/\D/,'').to_i unless price.nil?
    sleep(1+rand()*30) #Be nice to Amazon
    priceint
  end

  def getAtts(n, o)
    cols = $model.column_names.delete_if{|c|c.index(/^id|updated_at|created_at|manufacturerproducturl$/)}
    cols.each do |c|
      n.send((c+'=').intern, o.send(c.intern))
    end
    n
  end

  def download_review(p)
    current_page = 1
    a = nil
    begin
      a = AmazonPrinter.find_by_product_id_and_product_type(p.id,p.class.name)
    rescue
      return
    end
    return if a.nil?
    puts a.asin
    averagerating,totalreviews,totalreviewpages = nil
    loop do
      begin
        res = Amazon::Ecs.item_lookup(a.asin, :response_group => 'Reviews', :condition => 'New', :merchant_id => 'All', :review_page => current_page)
      rescue Exception => exc
        puts "Error: #{exc.message} for product #{p.asin} and merchant #{merchant}"
      end
      result = res.first_item
      #Look for old Retail Offering
      unless result.nil?
        averagerating ||= result.get('averagerating')
        totalreviews ||= result.get('totalreviews').to_i
        totalreviewpages ||= result.get('totalreviewpages').to_i
        reviews = result.search_and_convert('review')
        reviews = Array(reviews) unless reviews.class == Array #Fix single and no review possibility
        reviews.each do |r|
          r = Review.new(r.get_hash.merge({'product_type' => a.product_type, 'product_id' => a.product_id, "source" => "Amazon"}))
          r.save
        end
      else
        return
      end
      current_page += 1
      break if current_page > totalreviewpages
      sleep(2) #Be nice to Amazon
    end
    a.averagereviewrating = averagerating
    a.totalreviews = totalreviews
    a.save
    p.averagereviewrating = averagerating
    p.totalreviews = totalreviews
    p.save
  end
  
  def get_camera_attributes(camera)
    res = Amazon::Ecs.item_lookup(camera.asin, :response_group => 'ItemAttributes')
    r = res.first_item
    unless r.nil?
      camera.detailpageurl = r.get('detailpageurl')
      atts = r.search_and_convert('itemattributes')
      camera.batteriesincluded = atts.get('batteriesincluded')
      camera.batterydescription = atts.get('batterydescription')
      camera.binding = atts.get('binding')
      camera.brand = atts.get('brand')
      camera.connectivity = atts.get('connectivity')
      camera.digitalzoom = atts.get('digitalzoom') #in terms of x
      camera.displaysize = atts.get('displaysize') #in inches
      camera.ean = atts.get('ean')
      camera.feature = atts.get_array('feature').join("\n")
      camera.floppydiskdrivedescription = atts.get('floppydiskdrivedescription')
      camera.hasredeyereduction = atts.get('hasredeyereduction')
      camera.includedsoftware = atts.get('includedsoftware')
      camera.isautographed = atts.get('isautographed')
      camera.ismemorabilia = atts.get('ismemorabilia')
      camera.itemheight = atts.get('itemdimensions/height') #hundredths-inches
      camera.itemlength = atts.get('itemdimensions/length')
      camera.itemwidth = atts.get('itemdimensions/width')
      camera.itemweight = atts.get('itemdimensions/weight') #hundredths-pounds
      camera.label = atts.get('label')
      camera.listpriceint = atts.get('listprice/amount') #cents
      camera.listpricestr = atts.get('listprice/formattedprice')
      camera.manufacturer = atts.get('manufacturer')
      camera.maximumfocallength = atts.get('maximumfocallength') #mm
      camera.maximumresolution = atts.get('maximumresolution') #MP
      camera.minimumfocallength = atts.get('minimumfocallength') #mm
      camera.model = atts.get('model')
      camera.mpn = atts.get('mpn')
      camera.opticalzoom = atts.get('opticalzoom') #in terms of x
      camera.packageheight = atts.get('packagedimensions/height') #hundredths-inches
      camera.packagelength = atts.get('packagedimensions/length')
      camera.packagewidth = atts.get('packagedimensions/width')
      camera.packageweight = atts.get('packagedimensions/weight') #hundredths-pounds
      camera.productgroup = atts.get('productgroup')
      camera.publisher = atts.get('publisher')
      camera.releasedate = atts.get('releasedate')
      camera.specialfeatures = atts.get('specialfeatures')
      camera.studio = atts.get('studio')
      camera.title = atts.get('title')
    end

    #Lookup images
    res = Amazon::Ecs.item_lookup(camera.asin, :response_group => 'Images')
    r = res.first_item
    unless r.nil?
      camera.imagesurl = r.get('smallimage/url')
      camera.imagesheight = r.get('smallimage/height')
      camera.imageswidth = r.get('smallimage/width')
      camera.imagemurl = r.get('mediumimage/url')
      camera.imagemheight = r.get('mediumimage/height')
      camera.imagemwidth = r.get('mediumimage/width')
      camera.imagelurl = r.get('largeimage/url')
      camera.imagelheight = r.get('largeimage/height')
      camera.imagelwidth = r.get('largeimage/width')
    end
    
    camera = scrape_details(camera)
    
    camera.save!
  end
  
  def get_printer_attributes(p)
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
      p = interpret_special_features(p) if p.specialfeatures
      p.studio = atts.get('studio')
      p.systemmemorysize = atts.get('systemmemorysize')
      p.systemmemorytype = atts.get('systemmemorytype')
      p.title = atts.get('title')
      p.warranty = atts.get('warranty')
    
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
    
      p = scrape_details(p)
    
      p.save!
    end
  end
  
end

namespace :amazon do

desc "Collect all Product ASINs for a browse node"
task :get_product_ASINs => :init do
  #browse_node for printers: 172635
  #browse_node for all-in-one:172583
  #browse_node for digital point and shoot cameras: 330405011
  #Use browse id for Laser Printers - 172648
  browse_node_id = '172583'
  search_index = 'Electronics'
  response_group = 'ItemIds'
  current_page = 1
  count = 0
  loop do
    res = Amazon::Ecs.item_search('',:browse_node => browse_node_id, :search_index => search_index, :response_group => response_group, :item_page => current_page)
    total_pages = res.total_pages unless total_pages
    res.items.each do |item|
      asin = item.get('asin')
      if $amazonmodel.find_by_asin(asin).nil?
        product = $amazonmodel.new
        product.asin = asin
        product.save!
        puts asin
        count += 1
      end
    end
    current_page += 1
    sleep(0.2)
    break if (current_page > total_pages)
  end
  puts "Total new products: " + count.to_s
end

desc "Collect Product Reviews"
task :download_reviews => :init do
  $model.find(:all, :conditions => 'totalreviews is NULL').each do |p|
    puts "Downloading: #{p.id}"
    download_review(p)
  end
end

desc "Get all the Amazon data for the current Camera ASINs"
task :get_product_data_for_ASINs => :init do
  $amazonmodel.find(:all).each do |product|
    if !product.asin.blank?
      puts 'Processing: ' + product.asin
      if $amazonmodel == AmazonCamera
        get_camera_attributes(product)
      elsif $amazonmodel == AmazonPrinter
        get_printer_attributes(product)
      end
    end
    sleep(1+rand()*30) #Be really nice to Amazon!
  end
end

desc "Updating Amazon Price"
task :update_prices => :init do
  $model.find(:all).each{|p|# :conditions => ['updated_at < ?', 1.day.ago]).each {|p|
    puts 'Processing ' + p.id.to_s
    p = findprice(p,"us")
    p.save
    sleep(0.5) #One Req per sec
  }
end

desc "Create new printers for new AmazonPrinters"
task :create_products => :init do
  $amazonmodel.find_all_by_product_id(nil, :conditions => ['created_at > ?', 1.day.ago]).each do |p|
    product = $model.new
    product = getAtts(product, p)
    product.save
    p.update_attribute('product_id',product.id)
    product = findprice(product,"us")
    product.save
  end
end

desc "Find which printers are available in Canada"
task :update_prices_ca => :init do
  $model.find(:all).each{|p|#, :conditions => ['updated_at < ?', 1.day.ago]).each {|p|
    puts 'Processing ' + p.id.to_s
    p = findprice(p,"ca")
    p.save
    sleep(0.5) #One Req per sec
  }
end

task :init => :environment do
  require 'amazon/ecs'
  include Amazon
  $model = Printer
  $amazonmodel = AmazonPrinter
  Amazon::Ecs.options = {:aWS_access_key_id => '1JATDYR69MNPGRHXPQG2'}
  AmazonID =   'ATVPDKIKX0DER'
  AmazonCAID = 'A3DWYIK6Y9EEQB'
end

end

