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
  
  def vote_on_id_fields sps, avg_atts={}
    # vote on models & mpns
    # TODO: this shouldn't be here
    vals =  no_blanks(sps.collect{|x| [x.model,x.mpn]}.flatten)
    uniq_vals = remove_duplicate_models(vals, $series)
    sorted_vals = uniq_vals.sort{|a,b| likely_model_name(b) <=> likely_model_name(a)}
    #puts "MODELS VOTING: before #{vals * ', '}, after : #{sorted_vals[0..1] * ', '}"
    #debugger
    avg_atts['model'] = sorted_vals[0]
    avg_atts['mpn'] = sorted_vals[1]      
    return avg_atts
  end
  
  def vote_on_values product
    sps = $scrapedmodel.find_all_by_product_id(product.id)
    dontvote = ['itemheight', 'itemwidth', 'itemlength', 'price', 'price_ca']
    atts = $model::ContinuousFeatures + ['ttp', 'itemweight'] - dontvote
    #atts = [ 'itemweight',  'ppm', 'ttp', 'paperinput', 'resolutionmax','scanner', 'printserver']
    
    all_atts = {}
    atts.each{|x| all_atts[x] = [product.[](x)]} # Current value counts for something too...
    
    #... if valid! TODO: this should not, in theory, be necessary
    atts.each do |k|
      unless in_range?( k,all_atts[k][0],$model)
        puts "WARNING #{k}=#{all_atts[k][0]} not in range for #{$model.name}"
        all_atts[k] = []
      end
    end
    
    #TODO This should be somewhere else:
    if !all_atts['resolution'].nil? and all_atts['resolutionmax'].nil?
      all_atts['resolutionmax'] = get_max_f(all_atts['resolution']).to_s
    end
    
    atts.each do |att|
      sps.each do |sp|
        all_atts[att] << sp[att] if( sp[att] and in_range?(att,sp[att],$model) ) # and valid 
      end
    end
    
    avg_atts = {}
    all_atts.each{|att,vals| avg_atts[att] = vote(vals)}
    
    # vote on dimensions
    dimlabels = ['itemlength', 'itemheight', 'itemwidth']
    all_dimsets = (sps|[product]).collect{|sp| dimlabels.collect{|x| sp[x]}}
    all_dimsets.delete_if{|x| x.include?(nil) or x.include?(0)} # Remove invalid dimensions
    best_dimset = vote_on_dimensions(all_dimsets)
    if best_dimset and best_dimset != []
      dimlabels.size.times{ |i| avg_atts[dimlabels[i]] = best_dimset[i] } 
      avg_atts['dimensions'] = dims_to_s(avg_atts)
    end
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
      
      clean_atts = clean(scraped_atts)
      sp = find_or_create_scraped_product(clean_atts)
            
      if sp
        clean_atts['url'] = id_to_sponsored_link(local_id, retailer.region, clean_atts['merchant'])
        ros = find_ros_from_scraped(sp)
        ro = ros.first
        if ro.nil?
          ro = create_record_from_atts(clean_atts, RetailerOffering)
        end
        fill_in_all(clean_atts, ro)
        timestamp_offering(ro)     
      else
        report_error "Couldn't create #{$scrapedmodel} with local_id #{local_id || 'nil'} and retailer #{retailer_id || 'nil'}."
      end
    else
      # If there was an error while scraping: sleep 20 min
      log_snore(20*60)
    end
  end  
end

namespace :data do
  
  task :amazon_reviews => [:cam_init, :amazon_init, :reviews]
  
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
    timed_announce "Done!"
    @logfile.close
  end
  
  task :rescrape_stats do 
    #att = 'itemwidth' # This will be re-scraped.
    atts = ['itemlength', 'itemwidth', 'itemheight']
    allproducts = $model.instock | $model.instock_ca # $model.all
    #no_stats = allproducts.reject{|y| # These are the products for which we need to re-scrape.
    #  !y[att].nil? and y[att] > 100 and y[att] < 7000 # What is OK for this att
    #}.reject{|x| 
    #  !x.instock and !x.instock_ca}.collect{|x| 
    #  x.id
    #}
    no_stats = allproducts.collect{|x| x.id}
    no_stats_fixed = [] # The ones we've fixed will go here.
    
    retailerids = $retailers.collect{|x| x.id} 
    
    no_stats.each do |pid| 
      sps = $scrapedmodel.find_all_by_product_id(pid)
      newvals = nil
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
          #if retailer_ok_sp[att].nil?
          #  puts "#{spid} has a nil #{att}..."
          #else
          unless atts.collect{|x| retailer_ok_sp[x]}.include?(nil)
            newvals ||= retailer_ok_sp.attributes
            puts "#{spid} has been fixed!"
            no_stats_fixed << pid
          end
          #end
        end
      end
      
      p = $model.find(pid)
      puts "Dims for #{pid} were: #{p.itemlength} x #{p.itemheight} x #{p.itemwidth}"
      avgs = vote_on_values(p)
      fill_in_all avgs, p
      p = $model.find(pid)
      puts "Done #{pid}. New dims #{p.itemlength} x #{p.itemheight} x #{p.itemwidth}"
      #if newval and newval > 0 and newval < 7000
        #p = $model.find(pid)
        #atts.each{ |att| fill_in(att,newvals[att],p) } if newvals
      #end
      
    end
    puts "There were #{no_stats.count} printers w/o stats of which #{no_stats_fixed.count} were fixed"
  end
  
  desc 'Get new prices and products from Amazon cameras'
  task :scrape_amazon_cams => [:cam_init, :amazon_init, :scrape_new, :update_prices]
    
  task :validate_amazon => [:printer_init,:amazon_init, :validate_printers]
  
  # The 2 things you can do, in terms of subtasks: scrape and update
  task :scrape => [:scrape_new, :match_to_products, :update_bestoffers]
  task :update => [:update_prices, :scrape_new, :match_to_products, :update_bestoffers]
  
  task :endstuff => [:match_to_products, :vote, :update_bestoffers]
  
  # Useful combinations of the above
  desc 'Get new prices and products from Newegg printers'
  task :update_newegg_printers => [:newegg_init, :update]
  
  desc 'Get new prices and products from TigerDirect printers'
  task :update_tiger_printers => [:tiger_init, :update]
  
  desc 'Get new prices and products from Amazon (printers)'
  task :update_amazon_printers => [:printer_init, :amazon_init, :update]
  
  desc 'Get new prices and products from Amazon Marketplace (printers)'
  task :update_amazon_mkt_printers => [:printer_init, :amazon_mkt_init, :update]
   
  desc 'Get new products from Amazon (warning:extra long!)'
  task :scrape_amazon_printers => [:printer_init, :amazon_init, :scrape]
  
  desc 'Get new products from Newegg'
  task :scrape_newegg_printers => [:newegg_init, :scrape]
  
  desc 'Get new products from TigerDirect'
  task :scrape_tiger_printers => [:tiger_init, :scrape]
    
  desc 'Get new products from Amazon Marketplace (warning: extra long!)'
  task :scrape_amazon_mkt_printers => [:printer_init, :amazon_mkt_init, :scrape]
  
  # ... for cams
  
  
  desc 'Get new prices and products from Amazon (printers)'
  task :update_amazon_cameras => [:cam_init, :amazon_init, :update]
  
  desc 'Get new prices and products from Amazon Marketplace (printers)'
  task :update_amazon_mkt_cameras => [:cam_init, :amazon_mkt_init, :update]
  
  
   # The subtasks...
  task :vote do 
    products = $model.all
    products.each do |p|
      avgs = vote_on_values p
      $bools_assume_no.each{|x| avgs[x] = false if avgs[x].nil?}
      #avgs.each do |k,v|
      #  puts "#{k} -- #{v} (now #{p.[](k)}) for #{p.id}" #if [v, p.[](k)].uniq.reject{|x| x.nil?}.length > 1
      #end
      fill_in_all avgs, p
    end
  end
  
  desc 'Match ScrapedPrinter to Printer!'
  task :match_to_products do 
    puts "[#{Time.now}] Starting to match products"
    match_me = scraped_by_retailers($retailers, $scrapedmodel) if $retailers
    match_me = $scrapedmodel.all if match_me.nil?
    
    #debugger
    match_me.delete_if{|x| x.product_id}
    
    #match_me = [4982, 7878, 10434, 12760, 23270,16024, 18286, 21544].collect{|x| $scrapedmodel.find(x)}
    #[25406,25468,23376,21146,18848, 19564,21852,21232,21524,23266,21232,21292,23266,21928,23720,21544]
    
    #match_me = [3466, 8442, 14260, 23582, 5124, 10530, 15530, 23952, 25406, 25468, 3354, 8322, 13918, 19662].collect{|x| $scrapedmodel.find(x)}
    
    match_me.each do |sc|
      sc.update_attribute('product_id',nil)
    end
    #debugger
    
    puts "There are #{match_me.count} #{$scrapedmodel.name}s in total."
    
    match_me.delete_if{|x| (x.model.nil? and x.mpn.nil?) or x.brand.nil?}
    announce "#{match_me.count} #{$scrapedmodel.name}s are identifiable -- will match these."
    match_me.each_with_index do |scraped, i|
      matches = match_product_to_product scraped, $model, $series
      
      real = matches.first
      real = create_record_from_atts  scraped.attributes, $model if real.nil? 
      
      fill_in 'product_id',real.id, scraped
      
      ros = find_ros_from_scraped scraped, $model
      ros.each{ |ro| fill_in 'product_id', real.id, ro }     
      
      revues = Review.find_all_by_local_id_and_product_type(scraped.local_id, $model.name)
      revues.each{|revu| fill_in 'product_id', real.id, revu }
      #puts "[#{Time.now}] Done matching #{i+1}th scraped product." 
    end
    timed_announce "[#{Time.now}] Done matching products"
  end
  
  # Update prices
  task :update_prices do
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_#{$model.name}_scraper.log", 'w+')
    my_offerings = $retailers.inject([]){|r,x| r+RetailerOffering.find_all_by_retailer_id_and_product_type(x.id, $model.name)}
    my_offerings.each_with_index do |offering, i|
      begin
        next if offering.local_id.nil? #offering.stock != true
        newatts = rescrape_prices( offering.local_id, offering.region)
        
        #log "[#{Time.now}] Updating #{offering.pricestr} to #{newatts['pricestr']}"
        update_offering(newatts, offering) if offering
        if( offering.product_id and $model.exists?(offering.product_id))
          update_bestoffer($model.find(offering.product_id))
        end  
      rescue Exception => e
        report_error "with RetailerOffering #{offering.id}: #{e.class.name} #{e.message}"
        log_snore(20*60) # sleep for 20 min 
      end
      log "[#{Time.now}] Done updating #{i+1} of #{my_offerings.count} offerings"
    end
    
    timed_announce "Done updating prices"
    @logfile.close
  end

  # Scrape all data for all current products
  task :scrape_all do
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_#{$model.name}_scraper.log", 'w+')
    $retailers.each do |retailer|
      
      ids = scrape_all_local_ids retailer.region
      old_ids = (RetailerOffering.find_all_by_retailer_id(retailer.id)).collect{|x| x.local_id}
      ids = (ids + old_ids).uniq.reject{|x| x.nil?}
      
      announce "Will scrape #{ids.count} #{$model.name}s from #{retailer.name}"
            
      ids.each_with_index do |local_id, i|
        generic_scrape(local_id, retailer)
        log "[#{Time.now}] Progress: done #{i+1} of #{ids.count} #{$model.name}s..."
      end
    end
    timed_announce "Done scraping"
    @logfile.close
  end
  
  # Scrape all data for new products only
  task :scrape_new do
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_#{$model.name}_scraper.log", 'w+')
    $retailers.each do |retailer|
      ids = scrape_all_local_ids retailer.region
      scraped_ids = ($scrapedmodel.find_all_by_retailer_id(retailer.id)).collect{|x| x.local_id}.uniq
      ids = (ids - scraped_ids).uniq.reject{|x| x.nil?}
      announce "Will scrape #{ids.count} #{$model.name}s from #{retailer.name}, #{scraped_ids.count} already exist"
      
      ids.each_with_index do |local_id, i|
        generic_scrape(local_id, retailer)
        log "[#{Time.now}] Progress: done #{i+1} of #{ids.count} #{$model.name}s..."
      end
    end
    timed_announce "Done scraping"
    @logfile.close
  end
  
  desc "Check that scraped data isn't wonky"
  task :validate_printers do
    require 'helpers/validation/data_validator'
    include DataValidator
    
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_#{$model.name}_validation.log", 'w+')
    
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
    timed_announce "Done with validation"
    @logfile.close
  end
  
  task :update_bestoffers do 
    $model.all.each do |p|
      update_bestoffer p
    end
    timed_announce "Done updating bestoffers"
  end

  task :cam_init => :init do
      include CameraHelper
      include CameraConstants
      
      # TODO get rid of this construct:
      $model = @@model
      $scrapedmodel = @@scrapedmodel
      $brands= @@brands
      $series = @@series
      $descriptors = @@descriptors | $colors.collect{|x| /(-|\s)?#{x}/i} 
      
      $reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'opticalzoom', 'maximumresolution', \
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
      $descriptors = @@descriptors + $conditions.collect{|cond| /(\s|^|;|,)#{cond}(\s|,|$)/i} \
        + $units.reject{|x| x=='in'}.collect{|y| /#{Regexp.escape(y)}/i}
      
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
    require 'amazon/ecs'
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