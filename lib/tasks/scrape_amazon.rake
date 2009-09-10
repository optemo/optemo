module AmazonScraper
  
  def get_ASINs
    response_group = 'ItemIds'
    current_page = 1
    count = 0
    added = []
    loop do
      res = Amazon::Ecs.item_search('',:browse_node => $browse_node_id, :search_index => $search_index, :response_group => response_group, :item_page => current_page)
      sleep(1+rand()*30) #Be nice to Amazon
      report_error "ERROR: #{res.error}. Couldn't download ASINs for page #{current_page}" if  res.has_error?    
      total_pages = res.total_pages unless total_pages
      res.items.each do |item|
        asin = item.get('asin')
        if $amazonmodel.find_by_asin(asin).nil?
          added << asin
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
    return added
  end
  
  def scrape scrapeme
    count = 0
    scrapeme.each do |product|
      if !product.asin.blank?
        log ('Processing: ' + product.asin )
        if $amazonmodel == nil #  AmazonCamera
          get_camera_attributes(product)
        elsif $amazonmodel == AmazonPrinter
          get_printer_atts(product)
        elsif $amazonmodel == AmazonCartridge
          get_cartridge_atts(product)
        end
        log 'Done.'
      end
      count += 1
      debugger
      puts "Done #{count} of #{scrapeme.count}; waiting."
      sleep(1+rand()*30) #Be really nice to Amazon!
    end
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
        begin
          res = Amazon::Ecs.item_lookup(e.asin, :response_group => 'OfferListings', :condition => 'New', :merchant_id => 'All', :offer_page => current_page, :country => region.intern)
          sleep(1+rand()*30) #Be nice to Amazon
        rescue Exception => exc
          report_error "#{exc.message} . Could not look up offers for #{$amazonmodel} "+\
          "#{e.asin} (id #{p.id}) in region #{region}"
          sleep(30) 
          return
        else
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
        end
      end while (!total_pages.nil? and current_page <= total_pages)
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

    update_bestoffer p
  end

  def saveoffer(p,retailer,merchant,region)
    puts [p.product_id,Retailer.find(retailer).name,merchant,region].join(' ')
    begin
      res = Amazon::Ecs.item_lookup(p.asin, :response_group => 'OfferListings', :condition => 'New', :merchant_id => merchant, :country => region.intern)
      sleep(1+rand()*30) #Be nice to Amazon
    rescue Exception => exc
      report_error " -- #{exc.message}. Could not look up offer to save for #{$amazonmodel} #{p.asin}"+\
      " and merchant #{merchant} in region #{region}"
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
        sleep(1+rand()*30) #Be nice to Amazon
      rescue Exception => exc
        report_error " --  #{exc.message}. Couldn't download reviews for product #{a.asin} and merchant #{merchant}"
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
  
  def get_attributes(rec)
    res = Amazon::Ecs.item_lookup(rec.asin, :response_group => 'ItemAttributes')
    sleep(1+rand()*30) #Be nice to Amazon
    nokodoc = Nokogiri::HTML(res.doc.to_html)
    item = nokodoc.css('item').first
    if item
      detailurl = item.css('detailpageurl').first.content
      atts = item.xpath('itemattributes/*').inject({}){|r,x| 
        val = x.content
        val += "#{CleaningHelper.sep} #{r[x.name]}" if r[x.name]
        r.merge(x.name => val)
      }
      return atts
    end
    return {}
  end
  
  def get_printer_atts(p)
    # Never been tested...
    atts = get_attributes p
    cleaned_atts = generic_printer_cleaning_code atts
    # TODO check that it worked..'
    debugger
    fill_in_all cleaned_atts, p
    debugger
    return p
  end
  
  def get_cartridge_atts(cart)
    atts = get_attributes cart
    cleaned_atts = cartridge_cleaning_code atts
    
    init_brands
    init_series
        
    cleaned_atts['realbrand'] = clean_brand(cleaned_atts['brand'], $fake_brands+$real_brands)
    cleaned_atts['compatiblebrand'] = clean_brand(cleaned_atts['title'])
    cleaned_atts['real'] = same_brand?(cleaned_atts['realbrand'], cleaned_atts['compatiblebrand'])
    cleaned_atts['toner'] = true if (cleaned_atts['title'] || '').match(/toner/i) 
    cleaned_atts['toner'] = false if (cleaned_atts['title'] || '').match(/ink/i) 
    
    conditions = ['Remanufactured', 'Refurbished', 'Compatible', 'OEM', 'New']
    conditions.each{|c| 
      (cleaned_atts['condition'] = c) and break if (cleaned_atts['title'] || '').match(/#{c}/i)
    }
    
    cleaned_atts['compatible'] = cleaned_atts['feature'] + "#{cleaned_atts['compatible']}" if cleaned_atts['feature']
    fill_in_all cleaned_atts, cart
  end
end

namespace :scrape_amazon do
  
  # -- Useful combos -- #
  
  desc 'Update printer images'
  task :update_printer_pix => [:prnt_init, :update_pix, :copy_pic_stats, :closelog] 
  
  desc 'Update cartridge images'
  task :update_cart_pix => [:crtg_init, :update_pix, :copy_pic_stats, :closelog]
  
  desc 'Update printer records'
  task :update_printer_prices => [:prnt_init, :get_new_products, :update_prices, :closelog] 
  
  desc 'Update cartridge records'
  task :update_cart_prices => [:crtg_init, :get_new_products, :update_prices, :closelog]
  
  desc 'Downloads new printers & scrapes the data'
  task :get_new_printers => [:prnt_init, :get_new_products]

  task :try_scraping => :prnt_init do
    recent_asins = ['B0026JL9RG'].collect{|x| $amazonmodel.find_by_asin(x)}
    scrape recent_asins
  end

  # Get a list of all products from and (re)scrape all data
  task :scrape_all => :init do
    recent_asins = get_ASINs
    puts "Total new products: " + recent_asins.count.to_s
    count = 0
    scrapeme = $amazonmodel.find(:all)
    scrape scrapeme
  end

  # Get a list of all products from and scrape data for new products only
  task :get_new_products do
    recent_asins = get_ASINs
    recent_entries = recent_asins.collect{|x| $amazonmodel.find_by_asin(x)}
    scrape recent_entries
  end
  
  task :update_prices => :init do
    $logfile.puts "Updating prices for #{$model}!"
    
    $model.all.each {|p|
      puts 'Processing ' + p.id.to_s
      p = findprice(p,"us")
      p.save
      sleep(0.5) #One Req per sec
      p = findprice(p,"ca")
      p.save
      sleep(0.5) #One Req per sec
    }
    $logfile.puts "Done updating #{$model} prices!"
  end
  
  task :download_reviews => :init do
    $logfile.puts "Downloading reviews"
    $model.find(:all, :conditions => 'totalreviews is NULL').each do |p|
      puts "Downloading: #{p.id}"
      download_review(p)
    end
    $logfile.puts "Done downloading reviews"
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
  
  # --- Picture rake tasks ---#
  
  task :update_pix => :pic_init do 
    log "Updating pix"
    
    log "Downloading missing pix.."
    dl_me = (picless_recs $amazonmodel)
    log "I've got #{dl_me.length} #{$model} pictures to download"
    failed= download_these(dl_me)
    report_error "couldn't download all pictures" if failed.length > 0
    log "#{failed.length} FAILED DOWNLOADS:" if failed.length > 0
    log (failed * "\n")

    
    log "Resizing pix .."
    resize_me = (unresized_recs $amazonmodel) + dl_me
    failed = resize_all(resize_me.collect{|x| x.id})
    report_error "Couldn't resize all pictures" if failed.length > 0
    log "#{failed.length} FAILED RESIZINGS:" if failed.length > 0
    log (failed * "\n")
    
    log "Recording missing sizes & urls for pix..."
    measure_me = $amazonmodel.all #(statless_recs $amazonmodel) + dl_me + resize_me
    failed = record_pic_stats(measure_me)
    report_error "Couldn't record all sizes/urls" if failed.length > 0
    log "Can't record sizes/urls for #{failed.length} records:" if failed.length > 0
    log (failed * "\n")
  end
  
  task :download_pix => :pic_init do 

    failed = []
    urls_by_id = $amazonmodel.all.inject({}){|r,x| r.merge({x.id => x.imagelurl}) }.reject{|x,y| 
      y.nil? or !y.include? 'http://'}
      
    failed = download_all_pix urls_by_id
    
    puts "#{failed.length} FAILED DOWNLOADS:" if failed.length > 0
    puts failed * "\n"
  end

  task :copy_pic_stats => :init do
    imageatts = $amazonmodel.column_names.reject{|x| !x.include?'image'}
    $amazonmodel.all.each do |ap|
      p = nil
      begin
        p = $model.find(ap.product_id)
      rescue
        #Do nuthin
      end
      imageatts.each{|att| fill_in att, ap.[](att), p } if !p.nil?
    end
  end
  
  #-- Inits --# 
  
  task :pic_init => :init do 
    require 'helper_libs'
    include ImageLib
    require 'open-uri'
    $id_field='id'
    $img_url_field='imagelurl'
    $imgfolder = "amazon/#{$amazonmodel.name.downcase}"
  end
    
  task :crtg_init => :init do 
    #browse node for cartridges: 172638
    #browse node for laser cartridges: 172641    
    $model = Cartridge
    $amazonmodel = AmazonCartridge
    $browse_node_id = '172641'
    $search_index = 'Electronics'
    $logfile = File.open("./log/amazon_cartridges.log", 'w+')
  end
  
  task :cam_init => :init do 
    #browse_node for digital point and shoot cameras: 330405011
    $browse_node_id = '330405011'
    $search_index = 'Electronics'
    $model = Camera
    $amazonmodel = Camera
    $logfile = File.open("./log/amazon_cameras.log", 'w+')
  end
  
  task :prnt_init => :init do 
    #browse_node for printers: 172635
    #browse_node for all-in-one:172583
    #Use browse id for Laser Printers - 172648
    $browse_node_id = '172648'
    $search_index = 'Electronics'
    $model = Printer
    $amazonmodel = AmazonPrinter
    $logfile = File.open("./log/amazon_printers.log", 'w+')
  end
  
  task :init => :environment do
    require 'amazon_ecs'
    include Amazon
    
    require 'old_amazon_helpers'
    include AmazonFeedScraper
    
    require 'nokogiri'
    include Nokogiri
    
    require 'helper_libs'
    include DataLib      
    
    Amazon::Ecs.options = { :aWS_access_key_id => '0NHTZ9NMZF742TQM4EG2', \
                            :aWS_secret_key => 'WOYtAuy2gvRPwhGgj0Nz/fthh+/oxCu2Ya4lkMxO'}
    
    AmazonID =   'ATVPDKIKX0DER'
    AmazonCAID = 'A3DWYIK6Y9EEQB'
  end
  
  task :closelog do
    $logfile.close
  end
  

end


