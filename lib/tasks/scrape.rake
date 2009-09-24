module GenericScraper
  # A generic scraping algorithm for 1 offering
  def generic_scrape local_id, retailer
    scraped_atts = scrape local_id, retailer.region
    if(scraped_atts)
      scraped_atts['local_id'] = local_id
      scraped_atts['product_type'] = $model.name
      scraped_atts['retailer_id'] = retailer.id
      scraped_atts['region'] = retailer.region
      
      clean_atts = clean scraped_atts
      
      # TODO the only non-general line of code:
      sp = find_or_create_scraped_printer(clean_atts)
      
      clean_atts['url'] = id_to_sponsored_link(local_id, retailer.region, clean_atts['merchant'])
      ros = find_ros_from_scraped sp
      ro = ros.first
      
      ro = create_product_from_atts clean_atts, RetailerOffering if ro.nil?
      fill_in_all clean_atts, ro
            
      timestamp_offering ro       
    else
      # If there was an error while scraping: sleep 20 min
      snore(20*60)
    end
  end
end

namespace :printers do
  
  task :validate_amazon => [:amazon_init, :validate_printers]
  
  task :scrape_amazon => [:amazon_init, :scrape_all]
  
  task :scrape_newegg => [:newegg_init, :scrape_all, :match_to_products, :validate_printers]
  
  task :scrape_tiger => [:tiger_init, :scrape_all, :match_to_products, :validate_printers]
  
  task :update_prices_newegg => [:newegg_init, :update_prices, :scrape]
  
  task :update_prices_tiger => [:tiger_init, :update_prices, :scrape]
  
  task :once => :init do
    #retailers = ScrapedPrinter.all.collect{|x| x.retailer_id}.uniq
    #retailers.each do |x|
    #  RetailerOffering.find_all_by_retailer_id(x)
    #end
    ids = (RetailerOffering.all.collect{|x| x.id} - RetailerOffering.find_all_by_local_id(nil).collect{|x| x.id})
    fields = [ "product_id", "priceint", "pricestr", "tax", "state", "stock", "pricehistory", "toolow", "availability", "iseligibleforsupersavershipping", "merchant", "url", "created_at", "updated_at", "shippingCost", "freeShipping", "priceUpdate", "availabilityUpdate", "active", "activeUpdate", "region", "condition"]
    ids.each do |id|
      ro = RetailerOffering.find(id)
      fields.each do |field|
        ro.update_attribute(field,nil)
      end
      0
    end
  end
  
  desc 'Match ScrapedPrinter to Printer!'
  task :match_to_products do 
    match_me = scraped_by_retailers($retailers, $scrapedmodel) if $retailers
    match_me = $scrapedmodel.all if match_me.nil?
    
    match_me.each do |scraped|
      matches = match_printer_to_printer scraped, $model, $product_series
      real = matches.first
      real = create_product_from_atts scraped.attributes, $model if real.nil? 
      
      fill_in 'product_id',real.id, scraped
      
      ros = find_ros_from_scraped scraped, $model
      ros.each{ |ro| fill_in 'product_id', real.id, ro }      
    end
  end
  
  # Update prices
  task :update_prices do
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_scraper.log", 'w+')
    my_offerings = $retailers.inject([]){|r,x| r+RetailerOffering.find_all_by_retailer_id(x.id)}
    my_offerings.each_with_index do |offering, i|
      begin
        next if offering.local_id.nil? # TODO
        newatts = rescrape_prices offering.local_id, offering.region
        log "Updating #{offering.pricestr} to #{newatts['pricestr']}"
        update_offering newatts, offering if offering
        update_bestoffer($model.find(offering.product_id)) if offering.product_id
      rescue Exception => e
        report_error "with RetailerOffering #{offering.id}:" + e.message.to_s + e.type.to_s
        snore(20*60) # sleep for 20 min 
      end
      #debugger
      puts "Done updating #{i+1} of #{my_offerings.count} offerings"
    end
    
    @logfile.close
  end

  # Scrape all data for all current products
  task :scrape_all do
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_scraper.log", 'w+')
    $retailers.each do |retailer|
      
      ids = scrape_all_local_ids retailer.region
      old_ids = (RetailerOffering.find_all_by_retailer_id(retailer.id)).collect{|x| x.local_id}
      ids = (ids + old_ids).uniq
            
      ids.each_with_index do |local_id, i|
        generic_scrape(local_id, retailer)
        announce "Progress: done #{i+1} of #{ids.count} #{$model.name}s..."
      end
    end
    @logfile.close
  end
  
  # Scrape all data for new products only
  task :scrape do
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_scraper.log", 'w+')
    $retailers.each do |retailer|
      ids = scrape_all_local_ids retailer.region
      scraped_ids = (RetailerOffering.find_all_by_retailer_id(retailer.id)).reject{|x| 
        x.product_id.nil? }.collect{|x| x.local_id}
      ids = (ids - scraped_ids).uniq
            
      ids.each_with_index do |local_id, i|
        generic_scrape(local_id, retailer)
        announce "Progress: done #{i+1} of #{ids.count} #{$model.name}s..."
      end
    end
    @logfile.close
  end
  
  desc "Check that scraped data isn't wonky"
  task :validate_printers do
    include ValidationHelper
    
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_validation.log", 'w+')
    
    my_products = scraped_by_retailers($retailers, $scrapedmodel)
    
    announce "Testing #{my_products.count} #{$scrapedmodel.name} for validity..."
    
    reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'ppm', 'resolutionmax',\
       'paperinput','scanner', 'printserver', 'brand', 'model']
    reqd_fields.each do |rf|
      assert_no_nils my_products, rf
    end   
    
    assert_no_repeats my_products, 'local_id'
    
    assert_within_range my_products, 'itemheight', 100, 10000
    assert_within_range my_products, 'itemlength', 100, 7000
    assert_within_range my_products, 'itemwidth', 100, 7000
    assert_within_range my_products, 'ppm', 2, 50
    assert_within_range my_products, 'paperinput', 20,2000
    assert_within_range my_products, 'ttp', 7,40
    assert_within_range my_products, 'resolutionmax', 600, 4800
    
    my_offerings = $retailers.inject([]){|r,x| r+RetailerOffering.find_all_by_retailer_id(x.id)}
    
    announce "Testing #{my_offerings.count} RetailerOfferings for validity..."
    
    reqd_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
      'local_id', "product_type", "region", "retailer_id"]
    reqd_fields.each do |rf|
      assert_no_nils my_offerings, rf
    end
    
    assert_no_repeats my_offerings, 'local_id'
    assert_within_range my_offerings, 'priceint', 100, 10_000_00  
    
    @logfile.close
  end

  task :printer_init => :init do
      require 'rubygems'
      require 'nokogiri'

      require 'helper_libs'
      include DataLib

      require 'open-uri'

      $model = Printer
      $scrapedmodel = ScrapedPrinter
      $product_series = $printer_series
  end
    
  task :amazon_mkt_init => [:printer_init, :amazon_init] do
    $retailers = [Retailer.find(2),Retailer.find(10)]
  end
  
  task :amazon_init => :printer_init do
    require 'amazon_ecs'
    include Amazon
    
    require 'nokogiri'
    include Nokogiri
    
    require 'scrapers/amazon_scraper'
    include AmazonScraper
    
    Amazon::Ecs.options = { :aWS_access_key_id => '0NHTZ9NMZF742TQM4EG2', \
                            :aWS_secret_key => 'WOYtAuy2gvRPwhGgj0Nz/fthh+/oxCu2Ya4lkMxO'}
    
    AmazonID =   'ATVPDKIKX0DER'
    AmazonCAID = 'A3DWYIK6Y9EEQB'
    
    $search_index = 'Electronics'
    $browse_node_id = case $model.name
      when 'Printer'
        '172648'
      when 'Camera'
        '330405011'
      when 'Cartridge'
        '172641'
    end
    $retailers = [Retailer.find(1),Retailer.find(8)]
  end

  task :newegg_init => :printer_init do
    
    require 'scrapers/newegg_scraper'
    include NeweggScraper
    
    $retailers = [Retailer.find(4),Retailer.find(20)]
  end

  task :tiger_init => :printer_init do
    require 'scrapers/tiger_scraper'
    include TigerScraper

    @ignore_list = ['local_id', 'pricestr', 'price', 'region']
    $retailers = [Retailer.find(12), Retailer.find(14)]
  end

  task :init => :environment do 
    include GenericScraper
  end
end