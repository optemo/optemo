module GenericScraper
  
  def vote_on_values product
    sps = $scrapedmodel.find_all_by_product_id(product.id)
    #ignore = ["id", "price", "pricestr", "region", "created_at", "updated_at", "instock", "instock_ca", "price_ca", "price_ca_str"]
    #atts = $model.column_names - ignore
   # atts = $reqd_fields
   # 'itemheight', 'itemwidth','itemlength',
    atts = [ 'itemweight',  'ppm', 'ttp', 'paperinput','scanner', 'printserver']
    
    all_atts = {}
    atts.each{|x| all_atts[x] = [product.[](x)]} # Current value counts for something too?
    atts.each do |att|
      sps.each do |sp|
        all_atts[att] << sp.[](att) if sp.[](att)
      end
    end
    
    avg_atts = {}
    all_atts.each{|att,vals| avg_atts[att] = vote(vals)}
    
    return avg_atts
  end
  
  # A generic scraping algorithm for 1 offering
  def generic_scrape local_id, retailer
    scraped_atts = scrape local_id, retailer.region
    if(scraped_atts)
      scraped_atts['local_id'] = local_id
      scraped_atts['product_type'] = $model.name
      scraped_atts['retailer_id'] = retailer.id
      scraped_atts['region'] = retailer.region
      
      clean_atts = clean scraped_atts
      
      # TODO make sure ALL data is being properly scraped for Amazon
      # debugger if clean_atts['ppm'].nil? # resolution, paperinput
      
      # TODO the only non-general line of code:
      sp = find_or_create_scraped_printer(clean_atts)
      if sp
        clean_atts['url'] = id_to_sponsored_link(local_id, retailer.region, clean_atts['merchant'])
        ros = find_ros_from_scraped sp
        ro = ros.first
      
        ro = create_product_from_atts clean_atts, RetailerOffering if ro.nil?
        fill_in_all clean_atts, ro
            
        timestamp_offering ro       
      else
        report_error "Couldn't create ScrapedPrinter with local_id #{local_id || 'nil'} and retailer #{retailer_id || 'nil'}."
      end
    else
      # If there was an error while scraping: sleep 20 min
      snore(20*60)
    end
  end
end

namespace :printers do
  
  task :dlpixurls => [:amazon_init, :rescrape_pix]
  
  task :rescrape_pix do 
    no_resized_pix = $model.find_all_by_imagesurl_and_instock(nil, true).collect{|x| x.id}
    
    no_pix = []
    no_pix_fixed = []
    
    retailerids = $retailers.collect{|x| x.id}
    
    no_resized_pix.each do |pid| 
      sps = $scrapedmodel.find_all_by_product_id(pid)
      urls = sps.collect{|x| x.imageurl}.reject{|x| x.nil?}
      
      if urls.length == 0 and sps.length != 0
        retailer_ok_sps = sps.reject{|x| !retailerids.include?(x.retailer_id)}
        if retailer_ok_sps.length == 0
          puts "Oops -- no scraped printer from #{$retailers.first.name} for #{pid}"
        end
        
        retailer_ok_sps.each do |retailer_ok_sp|
          local_id = retailer_ok_sp.local_id
          retailer = Retailer.find(retailer_ok_sp.retailer_id)
          generic_scrape(local_id, retailer)
          
          if retailer_ok_sp.imageurl.nil?
            puts "Oops -- no image url available for SP #{retailer_ok_sp.id}... (printer #{pid})"
          else
            no_pix_fixed << pid
            puts "Fixed printer with id #{pid}."
            break
          end
        end
        no_pix << pid 
      end
    end
    puts "There were #{no_pix.count} printers w/o pic urls of which #{no_pix_fixed.count} were fixed"
    
  end
  
  task :validate_amazon => [:amazon_init, :validate_printers]
  
  # The 2 things you can do, in terms of subtasks: scrape and update
  task :scrape => [:scrape_new, :match_to_products, :update_bestoffers, :validate_printers]
  task :update => [:update_prices, :scrape_new, :match_to_products, :update_bestoffers, :validate_printers]
  
  # Scraping and updating by website...
  
  desc 'Update Newegg printers'
  task :update_newegg => [:newegg_init, :update]
  
  desc 'Update TigerDirect printers'
  task :update_tiger => [:tiger_init, :update]
  
  desc 'Update Amazon and AmazonMarketplace printers'
  task :update_amazon => [:amazon_init, :update, :amazon_mkt_init, :update]
  
  desc 'Scrape all data from Amazon (warning:extra long!)'
  task :scrape_amazon => [:amazon_init, :scrape]
  
  desc 'Scrape all data from Newegg'
  task :scrape_newegg => [:newegg_init, :scrape]
  
  desc 'Scrape all data from TigerDirect'
  task :scrape_tiger => [:tiger_init, :scrape]
    
  desc 'Scrape all data from Amazon Marketplace (warning: extra long!)'
  task :scrape_amazon_mkt => [:amazon_mkt_init, :scrape]
  
  # The subtasks...
  
  task :vote => :printer_init do 
    #include CleaningHelper
    printers = Printer.all
    printers.each do |p|
      avgs = vote_on_values p
      #fill_in_all avgs, p
      avgs.each do |k,v|
        puts "#{k} -- #{v} (now #{p.[](k)}) for #{p.id}" if [v, p.[](k)].uniq.reject{|x| x.nil?}.length > 1
      end
    end
  end
  
  desc 'Match ScrapedPrinter to Printer!'
  task :match_to_products do 
    puts "[#{Time.now}] Starting to match products"
    match_me = scraped_by_retailers($retailers, $scrapedmodel) if $retailers
    match_me = $scrapedmodel.all if match_me.nil?
    
    match_me = match_me.reject{|x| (x.model.nil? and x.mpn.nil?) or x.brand.nil?}
    
    match_me.each_with_index do |scraped, i|
      matches = match_printer_to_printer scraped, $model, $product_series
      real = matches.first
      real = create_product_from_atts scraped.attributes, $model if real.nil? 
      
      fill_in 'product_id',real.id, scraped
      
      ros = find_ros_from_scraped scraped, $model
      ros.each{ |ro| fill_in 'product_id', real.id, ro }     
      puts "[#{Time.now}] Done matching #{i+1}th scraped product." 
    end
    puts "[#{Time.now}] Done matching products"
  end
  
  # Update prices
  task :update_prices do
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_scraper.log", 'w+')
    my_offerings = $retailers.inject([]){|r,x| r+RetailerOffering.find_all_by_retailer_id(x.id)}
    my_offerings.each_with_index do |offering, i|
      begin
        next if offering.local_id.nil? or offering.stock != true
        newatts = rescrape_prices offering.local_id, offering.region
        log "[#{Time.now}] Updating #{offering.pricestr} to #{newatts['pricestr']}"
        update_offering newatts, offering if offering
        #update_bestoffer($model.find(offering.product_id)) if offering.product_id
      rescue Exception => e
        report_error "with RetailerOffering #{offering.id}:" + e.message.to_s + e.type.to_s
        snore(20*60) # sleep for 20 min 
      end
      puts "[#{Time.now}] Done updating #{i+1} of #{my_offerings.count} offerings"
    end
    
    @logfile.close
  end

  # Scrape all data for all current products
  task :scrape_all do
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_scraper.log", 'w+')
    $retailers.each do |retailer|
      
      ids = scrape_all_local_ids retailer.region
      old_ids = (RetailerOffering.find_all_by_retailer_id(retailer.id)).collect{|x| x.local_id}
      ids = (ids + old_ids).uniq.reject{|x| x.nil?}
      
      announce "Will scrape #{ids.count} #{$model.name}s from #{retailer.name}"
            
      ids.each_with_index do |local_id, i|
        generic_scrape(local_id, retailer)
        announce "[#{Time.now}] Progress: done #{i+1} of #{ids.count} #{$model.name}s..."
      end
    end
    @logfile.close
  end
  
  # Scrape all data for new products only
  task :scrape_new do
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_scraper.log", 'w+')
    $retailers.each do |retailer|
      ids = scrape_all_local_ids retailer.region
      scraped_ids = (ScrapedPrinter.find_all_by_retailer_id(retailer.id)).collect{|x| x.local_id}#.reject{|x|   x.product_id.nil? }
      ids = (ids - scraped_ids).uniq.reject{|x| x.nil?}
      ids = ids[0..300]
      announce "Will scrape #{ids.count} #{$model.name}s from #{retailer.name}"
      
      ids.each_with_index do |local_id, i|
        generic_scrape(local_id, retailer)
        announce "[#{Time.now}] Progress: done #{i+1} of #{ids.count} #{$model.name}s..."
      end
    end
    @logfile.close
  end
  
  desc "Check that scraped data isn't wonky"
  task :validate_printers do
    include ValidationHelper
    
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_validation.log", 'w+')
    
    my_products = scraped_by_retailers($retailers, $scrapedmodel,false)
    
    announce "Testing #{my_products.count} #{$scrapedmodel.name} for validity..."
    
    $reqd_fields.each do |rf|
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
    
    $reqd_offering_fields.each do |rf|
      assert_no_nils my_offerings, rf
    end
    
    assert_no_repeats my_offerings, 'local_id'
    assert_within_range my_offerings, 'priceint', 100, 10_000_00  
    
    @logfile.close
  end
  
  task :update_bestoffers do 
    $model.all.each do |p|
      update_bestoffer p
    end
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
      $reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'ppm', 'resolutionmax',\
         'paperinput','scanner', 'printserver', 'brand', 'model']
      $reqd_offering_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
         'local_id', "product_type", "region", "retailer_id"]
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
    config   = Rails::Configuration.new
    database = config.database_configuration[RAILS_ENV]["database"]
    puts "Using database #{database}"
    return if database == 'optemo_bestbuy'
  end
end