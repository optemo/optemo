module GenericScraper
  
  def no_blanks array
    return array.reject{|x| x.nil? or x.to_s.strip == ''}
  end
  
  def unlink_duplicate keepme, deleteme
    return if keepme.nil? or deleteme.nil?
    return if keepme.id.nil? or deleteme.id.nil?
    return if keepme.id == '' or keepme.id == 0 or deleteme.id == '' or deleteme.id == 0
    return if $model.name.nil? or $model.name == ''
    sps = $scrapedmodel.find_all_by_product_id(deleteme.id)
    ros = RetailerOffering.find_all_by_product_id_and_product_type(deleteme.id, $model.name)
    revus = Review.find_all_by_product_id_and_product_type(deleteme.id, $model.name)
    (sps+ros+revus).each do |x|
      fill_in 'product_id', keepme.id, x
    end
    temp = deleteme.id
    $model.delete(temp)
  end
  
  def vote_on_values product
    sps = $scrapedmodel.find_all_by_product_id(product.id)
    #ignore = ["id", "price", "pricestr", "region", "created_at", "updated_at", "instock", "instock_ca", "price_ca", "price_ca_str"]
    #atts = $model.column_names - ignore
   # atts = $reqd_fields
   # 'itemheight', 'itemwidth','itemlength',
    atts = [ 'itemweight',  'ppm', 'ttp', 'paperinput', 'resolutionmax','scanner', 'printserver']
    
    all_atts = {}
    atts.each{|x| all_atts[x] = [product.[](x)]} # Current value counts for something too?
    
    #TODO This should be somewhere else:
    if !all_atts['resolution'].nil? and all_atts['resolutionmax'].nil?
      all_atts['resolutionmax'] = get_max_f(all_atts['resolution']).to_s
    end
    atts.each do |att|
      sps.each do |sp|
        all_atts[att] << sp.[](att) if sp.[](att)
      end
    end
    
    avg_atts = {}
    all_atts.each{|att,vals| avg_atts[att] = vote(vals)}
    
    # vote on models & mpns
    vals =  no_blanks(sps.collect{|x| [x.model,x.mpn]}.flatten)
    debugger
    uniq_vals = remove_duplicate_models(vals, $series)
    temp = vote(uniq_vals)
    uniq_vals_2 = uniq_vals - [temp]
    avg_atts['model'] = temp
    avg_atts['mpn'] = vote(uniq_vals_2) if uniq_vals.length > 1      
    
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
      debugger
      sp = find_or_create_scraped_product(clean_atts)
      debugger
      if sp
        clean_atts['url'] = id_to_sponsored_link(local_id, retailer.region, clean_atts['merchant'])
        ros = find_ros_from_scraped sp
        ro = ros.first
        debugger
        ro = create_record_from_atts  clean_atts, RetailerOffering if ro.nil?
        debugger
        fill_in_all clean_atts, ro
        
        timestamp_offering ro     
        
        debugger
        0
          
      else
        report_error "Couldn't create #{$scrapedmodel} with local_id #{local_id || 'nil'} and retailer #{retailer_id || 'nil'}."
      end
    else
      # If there was an error while scraping: sleep 20 min
      snore(20*60)
    end
  end  
end

namespace :data do
  
  task :no_cam_dups => [:cam_init, :match_to_products]
  task :temp  => [:cam_init, :sandbox]

  task :sandbox do 
    
    fixme = ScrapedCamera.all.reject{|x| !x.product_id.nil?}.reject{|x| (x.model.nil? and x.mpn.nil?) or x.brand.nil?}
    puts "#{fixme.count} to fix"
    fixme[0..2000].each do |sc|
      ros = RetailerOffering.find_all_by_product_type_and_local_id('Camera', sc.local_id)
      ids = ros.collect{|x| x.product_id}.reject{|x| x.nil?}.first
      sc.update_attribute( 'product_id', ids) if ids
    end
  end

  task :no_dups do 
    puts "[#{Time.now}] Starting to match products"
    match_me = $scrapedmodel.all[0..100]
    
    match_me.delete_if{|x| (x.model.nil? and x.mpn.nil?) or x.brand.nil?}
    match_me.each_with_index do |scraped, i|
      dups = match_product_to_product scraped, $model, $series
      if dups.length > 1 
        debugger
        keep = dups.first
        lose = dups[1..-1].collect{|x| $model.find(x)}
        debugger
        lose.each do |deleteme|
          unlink_duplicate(keep, deleteme)
        end
        debugger 
        0
      end      
      puts "[#{Time.now}] Done matching #{i+1}th scraped product." 
    end
    puts "[#{Time.now}] Done matching products"
  end
  task :no_duplicates do    
    chekme = $scrapedmodel.all.
    
    allproducts.each do |prod|    
      dups =  match_product_to_product(prod, $model, $series)
      timed_announce "#{dups.length-1} duplicates for #{$model.name} #{prod.id}"
      if dups.length > 1
        keep = dups.first
        lose = dups[1..-1].collect{|x| $model.find(x)}
        debugger
        lose.each do |deleteme|
          unlink_duplicate(keep, deleteme)
        end
        debugger 
        0
      end
    end
  end
  
  task :amazon_reviews => [:cam_init, :amazon_init, :reviews]
  
  #task :temp => [:cam_init, :amazon_mkt_init, :match_to_products, :update_bestoffers, :vote]
  #task :temp3 => [:cam_init, :amazon_mkt_init, :match_to_products, :update_bestoffers, :match_reviews]
  
  task :match_reviews do    
    allrevus = Review.find_all_by_product_id_and_product_type(nil, $model.name)
    
    allrevus.each do |revu|    
      lid =  revu['local_id']
      sms = $scrapedmodel.find_all_by_local_id(lid)
      sms_pids = no_blanks(sms.collect{|x| x.product_id}.uniq)
      if sms_pids.length != 1 and sms_pids.length > 1
        keep = $model.find(sms_pids.first)
        lose = sms_pids[1..-1].collect{|x| $model.find(x)}
        lose.each do |deleteme|
          unlink_duplicate(keep, deleteme)
        end
      else
        fill_in 'product_id', sms_pids.first, revu
      end
      
    end
    
  end
    
  task :reviews do    
    total_before_script = Review.count
    @logfile =  File.open("./log/#{$model.name}_reviews.log", 'w+')
    $retailers.each do |ret|
      baseline = Review.count
      
      exclusion = Review.find_all_by_product_type($model.name).collect{|x| x.local_id}
      exclusion += $scrapedmodel.find_all_by_totalreviews(0).collect{|x| x.local_id}.uniq
      exclusion.uniq!
      getmyreviews = $scrapedmodel.find_all_by_retailer_id(ret.id).collect{|x| x.local_id}.uniq
      
      log "Getting reviews for #{(getmyreviews-exclusion).count} #{$model.name}s from #{ret.name}"
      
      getmyreviews.each do |local_id|
        next if exclusion.include?(local_id)
        baseline = Review.count

        revues = scrape_reviews(local_id, ret.id)
        revues.each do |rvu|
          rvu['product_type'] = $model.name
          r = find_or_create_review(rvu)
          fill_in_all(rvu,r) if r
          pid = r.product_id if r
          $scrapedmodel.find_all_by_local_id_and_retailer_id(local_id, ret.id).each do |sp|
            fill_in 'averagereviewrating',rvu["averagereviewrating"], sp if rvu["averagereviewrating"]
            fill_in 'totalreviews', rvu['totalreviews'], sp if rvu["totalreviews"]
            pid ||= sp.product_id
          end
          fill_in 'product_id', pid, r if pid and r
          report_error "Review #{r.id} has nil product_id" if r and r.product_id.nil?
        end
      end
    end  
    announce "#{Review.count - total_before_script} reviews added."
    announce "Done!"
    @logfile.close
  end
  
  task :dlmorestats => [:printer_init, :amazon_init, :rescrape_stats]
  
  task :dlmorepix => [:tiger_init, :rescrape_pix]
  
  task :rescrape_stats do 
    att = 'imageurl' # This will be re-scraped.
    
    allproducts = $model.instock | $model.ca # $model.all
    no_stats = allproducts.reject{|y| # These are the products for which we need to re-scrape.
      !y[att].nil?}.reject{|x| 
      !x.instock and !x.instock_ca}.collect{|x| 
      x.id
    }
    no_stats_fixed = [] # The ones we've fixed will go here.
    
    retailerids = $retailers.collect{|x| x.id} 
    
    no_stats.each do |pid| 
      sps = $scrapedmodel.find_all_by_product_id(pid)
      
      if sps.length != 0
        retailer_ok_sps = sps.reject{|x| !retailerids.include?(x.retailer_id)}
        if retailer_ok_sps.length == 0
          puts "Oops -- no scraped #{$model.name} from #{$retailers.first.name} for #{pid}"
        end
        
        retailer_ok_sps.each do |retailer_ok_sp|
          local_id = retailer_ok_sp.local_id
          retailer = Retailer.find(retailer_ok_sp.retailer_id)
          spid = retailer_ok_sp.id
          generic_scrape(local_id, retailer)
          if $scrapedmodel.find(spid)[att].nil?
            puts "#{spid} has a nil #{att}..."
          else
            puts "#{spid} has been fixed!"
            no_stats_fixed << pid
          end
        end
      end
    end
    puts "There were #{no_stats.count} printers w/o stats of which #{no_stats_fixed.count} were fixed"
    
  end
  
  task :validate_amazon => [:printer_init,:amazon_init, :validate_printers]
  
  # The 2 things you can do, in terms of subtasks: scrape and update
  task :scrape => [:scrape_new, :match_to_products, :update_bestoffers, :validate_printers]
  task :update => [:update_prices, :scrape_new, :match_to_products, :update_bestoffers, :validate_printers]
  
  desc 'Get new prices and products from Amazon cameras'
  task :scrape_amazon_cams => [:cam_init, :amazon_init, :scrape_new, :update_prices]
  
  desc 'Get new prices and products from Newegg printers'
  task :update_newegg => [:newegg_init, :update]
  
  desc 'Get new prices and products from TigerDirect printers'
  task :update_tiger => [:tiger_init, :update]
  
  desc 'Get new prices and products from Amazon and AmazonMarketplace printers'
  task :update_amazon => [:printer_init, :amazon_init, :update, :amazon_mkt_init, :update]
  
  desc 'Get new products from Amazon (warning:extra long!)'
  task :scrape_amazon => [:printer_init, :amazon_init, :scrape]
  
  desc 'Get new products from Newegg'
  task :scrape_newegg => [:newegg_init, :scrape]
  
  desc 'Get new products from TigerDirect'
  task :scrape_tiger => [:tiger_init, :scrape]
    
  desc 'Get new products from Amazon Marketplace (warning: extra long!)'
  task :scrape_amazon_mkt => [:printer_init, :amazon_mkt_init, :scrape]
  
  # The subtasks...
  
  task :vote do 
    products = $model.all
    products.each do |p|
      avgs = vote_on_values p
      $bools_assume_no.each{|x| avgs[x] = false if avgs[x].nil?}
      avgs.each do |k,v|
        puts "#{k} -- #{v} (now #{p.[](k)}) for #{p.id}" #if [v, p.[](k)].uniq.reject{|x| x.nil?}.length > 1
      end
      debugger
      fill_in_all avgs, p
    end
  end
  
  desc 'Match ScrapedPrinter to Printer!'
  task :match_to_products do 
    puts "[#{Time.now}] Starting to match products"
    match_me = scraped_by_retailers($retailers, $scrapedmodel) if $retailers
    match_me = $scrapedmodel.all if match_me.nil?
    
    match_me.delete_if{|x| (x.model.nil? and x.mpn.nil?) or x.brand.nil?}
    match_me.each_with_index do |scraped, i|
      matches = match_product_to_product scraped, $model, $series
      
      real = matches.first
      real = create_record_from_atts  scraped.attributes, $model if real.nil? 
      
      fill_in 'product_id',real.id, scraped
      
      ros = find_ros_from_scraped scraped, $model
      ros.each{ |ro| fill_in 'product_id', real.id, ro }     
      
      revues = Review.find_all_by_local_id_and_product_type(scraped.local_id, $model.name)
      revues.each{|revu| fill_in 'product_id', real.id, revu }
      
      puts "[#{Time.now}] Done matching #{i+1}th scraped product." 
    end
    puts "[#{Time.now}] Done matching products"
  end
  
  # Update prices
  task :update_prices do
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_scraper.log", 'w+')
    my_offerings = $retailers.inject([]){|r,x| r+RetailerOffering.find_all_by_retailer_id_and_product_type(x.id, $model.name)}
    my_offerings.each_with_index do |offering, i|
      #begin
        next if offering.local_id.nil? # or offering.stock != true
        newatts = rescrape_prices( offering.local_id, offering.region)
        
        # <<< debug
        puts "#{offering.priceint} changing to #{newatts['priceint']}"
        debugger 
        # end debug >>>>
        
        log "[#{Time.now}] Updating #{offering.pricestr} to #{newatts['pricestr']}"
        update_offering newatts, offering if offering
        
        #debug
        debugger if newatts['priceint'] != offering.priceint # uh oh
        
        update_bestoffer($model.find(offering.product_id)) if offering.product_id
        
        #<<<< debug
        temp = $model.find(offering.product_id)
        if temp.price > (newatts['priceint'] || 0) # uh oh
          puts "#{temp.price} #{newatts['priceint']}"
          debugger 
        end
        if( temp.price == (newatts['priceint'] || 0) and temp.bestoffer == offering.id )
          puts "this is the new best offer" 
        end
        # end debug>>>>
          
      #rescue Exception => e
      #  report_error "with RetailerOffering #{offering.id}:" + e.message.to_s + e.type.to_s
      #  snore(20*60) # sleep for 20 min 
      #end
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
      scraped_ids = ($scrapedmodel.find_all_by_retailer_id(retailer.id)).collect{|x| x.local_id}.uniq
      ids = (ids - scraped_ids).uniq.reject{|x| x.nil?}
      announce "Will scrape #{ids.count} #{$model.name}s from #{retailer.name}, #{scraped_ids.count} already exist"
      
      ids.each_with_index do |local_id, i|
        generic_scrape(local_id, retailer)
        announce "[#{Time.now}] Progress: done #{i+1} of #{ids.count} #{$model.name}s..."
      end
    end
    @logfile.close
  end
  
  desc "Check that scraped data isn't wonky"
  task :validate_printers do
    require 'helpers/validation/data_validator'
    include DataValidator
    
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
      debugger
      update_bestoffer p
      debugger
      0
    end
  end

  task :cam_init => :init do
      include CameraHelper
      include CameraConstants
      
      # TODO get rid of this construct:
      $model = @@model
      $scrapedmodel = @@scrapedmodel
      $brands= @@brands
      $series = @@series
      $descriptors = @@descriptors
      
      $reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'opticalzoom', 'resolutionmax', \
        'displaysize', 'slr', 'waterproof', 'brand', 'model', 'itemweight']
      $reqd_offering_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
         'local_id', "product_type", "region", "retailer_id"]
      $bools_assume_no = []
  end

  task :printer_init => :init do
      
      include PrinterHelper
      include PrinterConstants
      
      # TODO get rid of this construct:
      $model = @@model
      $scrapedmodel = @@scrapedmodel
      $brands= @@brands
      $series = @@series
      $descriptors = @@descriptors
      
      $reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'ppm', 'resolutionmax',\
         'paperinput','scanner', 'printserver', 'brand', 'model']
      $reqd_offering_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
         'local_id', "product_type", "region", "retailer_id"]
      $bools_assume_no = ['printserver', 'scanner']
  end
    
  task :amazon_mkt_init => :amazon_init do
    $retailers = [Retailer.find(2),Retailer.find(10)]
  end
  
  task :amazon_init do
    require 'amazon_ecs'
    include Amazon
    
    require 'nokogiri'
    include Nokogiri
    
    require 'helpers/sitespecific/amazon_scraper'
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
    
    require 'helpers/sitespecific/newegg_scraper'
    include NeweggScraper
    
    $retailers = [Retailer.find(4),Retailer.find(20)]
  end

  task :tiger_init => :printer_init do
    require 'helpers/sitespecific/tiger_scraper'
    include TigerScraper

    @ignore_list = ['local_id', 'pricestr', 'price', 'region']
    $retailers = [Retailer.find(12), Retailer.find(14)]
  end

  task :init => :environment do 
    config   = Rails::Configuration.new
    database = config.database_configuration[RAILS_ENV]["database"]
    puts "Using database #{database}"
    
    return if database == 'optemo_bestbuy'
    require 'rubygems'
    require 'nokogiri'

    require 'helper_libs'
    
    include GenericScraper    
    include ParsingLib
    include CleaningLib
    include LoggingLib
    include DatabaseLib
    include ScrapingLib
  end
end