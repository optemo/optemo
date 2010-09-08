module GenericScraper
  
  def unlink_duplicate(keepme, deleteme)
    [keepme, deleteme].each{|arg| return if arg.blank || arg.id.blank?}
    return if Session.current.product_type.blank? # This should never happen, but keep it just in case.
    sps = $scrapedmodel.find_all_by_product_id(deleteme.id)
    ros = RetailerOffering.find_all_by_product_id_and_product_type(deleteme.id, Session.current.product_type)
    reviews = Review.find_all_by_product_id_and_product_type(deleteme.id, Session.current.product_type)
    (sps+ros+reviews).each do |x|
      parse_and_set_attribute('product_id', keepme.id, x)
      x.save
    end
    temp = deleteme.id
    Product.delete(temp)
  end
  
  def vote_on_values(product)
    sps = $scrapedmodel.find_all_by_product_id(product.id)
    dimlabels = ['itemlength', 'itemheight', 'itemwidth']
    dontvote = ['price', 'price_ca'] | dimlabels
    atts = Session.current.continuous + ['ttp', 'itemweight'] - dontvote
    
    all_atts = {}
    atts.each{|x| all_atts[x] = [product.[](x)]} # Current value counts for something too...
    
    #... if valid! TODO: this should not, in theory, be necessary
    atts.each do |k|
      unless in_range?( k,all_atts[k][0])
        puts "WARNING #{k}=#{all_atts[k][0]} not in range for #{Session.current.product_type}"
        all_atts[k] = []
      end
    end
    
    #TODO This should be somewhere else:
    if !all_atts['resolution'].nil? and all_atts['resolutionmax'].nil?
      all_atts['resolutionmax'] = get_max_f(all_atts['resolution']).to_s
    end
    
    atts.each do |att|
      sps.each do |sp|
        all_atts[att] << sp[att] if( sp[att] and in_range?(att,sp[att]) ) # and valid 
      end
    end
    
    avg_atts = {}
    all_atts.each{|att,vals| avg_atts[att] = vote(vals)}
    
    # vote on dimensions
    dimsets = []
    # Get VALID DIM SETS ONLY
    (sps|[product]).each do |sp| 
      dimhash = dimlabels.inject({}){|r,x|
        r[x] = sp[x]
        r
      }
      next if dimhash.keys.include?(nil)
      validity = dimhash.collect{|k,v| in_range?(k,(v || 0))}
      if validity.uniq == [true]
        dimsets << dimhash.values
      end
    end
    
    best_dimset = vote_on_dimensions(dimsets)
    if best_dimset and best_dimset != []
      dimlabels.size.times{ |i| avg_atts[dimlabels[i]] = best_dimset[i] } 
      avg_atts['dimensions'] = dims_to_s(avg_atts)
    end
    return avg_atts
  end
  
  # A generic scraping algorithm for 1 offering
  def generic_scrape(local_id, retailer)
    scraped_atts = scrape_specs_and_offering_info(local_id, retailer.region)
    if(scraped_atts)
      scraped_atts['local_id'] = local_id
      scraped_atts['product_type'] = Session.current.product_type
      scraped_atts['retailer_id'] = retailer.id
      scraped_atts['region'] = retailer.region
      
      clean_atts = clean(scraped_atts)
      sp = find_or_create_scraped_product(clean_atts)
            
      if sp
        clean_atts['url'] = id_to_sponsored_link(local_id, retailer.region, clean_atts['merchant'])
        ros = find_ros_from_scraped(clean_atts["local_id"], clean_atts["retailer_id"])
        ro = ros.first
        if ro.nil?
          column_names = RetailerOffering.column_names
          retail_offering_atts = clean_atts.reject{|r| not column_names.index(r)}
          ro = RetailerOffering.new(retail_offering_atts)
        end

        # Validation!
        if clean_atts['priceint'] and (clean_atts['priceint'].to_i > Session.current.maximumPrice)# or newatts['priceint'] < Session.current.minimumPrice)
          clean_atts['stock'] = false
          clean_atts['priceint'] = nil
        end
        
        clean_atts.each{|name,val| parse_and_set_attribute(name, val, ro, ['pricehistory'])}
        parse_and_set_attribute('priceint', clean_atts['priceint'], ro) # Also validation
        
        timestamp_offering(ro)
        ro.save # Don't bother with the transaction for just the one record.  
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
    allreviews = Review.find_all_by_product_id_and_product_type(nil, Session.current.product_type)
    activerecords_to_save = []
    allreviews.each do |review|    
      lid =  review['local_id']
      sms = $scrapedmodel.find_all_by_local_id(lid)
      sms_pids = sms.collect{|x| x.product_id}.uniq.compact.reject(&:blank?)
      if sms_pids.length != 1 and sms_pids.length > 1
        keep = Session.current.product_type.find(sms_pids.first)
        lose = sms_pids[1..-1].collect{|x| Session.current.product_type.find(x)}
        lose.each do |deleteme|
          unlink_duplicate(keep, deleteme)
        end
      else
        parse_and_set_attribute('product_id', sms_pids.first, review)
      end
      activerecords_to_save.push(review)
    end
    Review.transaction do
      activerecords_to_save.each(&:save)
    end
  end
    
  task :reviews do    
    total_before_script = Review.count
    @logfile =  File.open("./log/scrape/reviews/#{Session.current.product_type}.log", 'w+')
    $retailers.each do |ret|
      baseline = Review.count
      
      exclusion = Review.find_all_by_product_type(Session.current.product_type).collect{|x| x.local_id}
      exclusion += $scrapedmodel.find_all_by_totalreviews(0).collect{|x| x.local_id}.uniq
      exclusion.uniq!
      getmyreviews = $scrapedmodel.find_all_by_retailer_id(ret.id).collect{|x| x.local_id}.uniq
      
      log "Getting reviews for #{(getmyreviews-exclusion).count} #{Session.current.product_type}s from #{ret.name}"
      
      getmyreviews.each do |local_id|
        next if exclusion.include?(local_id)
        baseline = Review.count

        reviews = scrape_reviews(local_id, ret.id)
        reviews.each do |rvu|
          rvu['product_type'] = Session.current.product_type
          r = find_or_create_review(rvu)
          rvu.each{|name,val| parse_and_set_attribute(name, val, r, ignorelist)} if r
          pid = r.product_id if r
          $scrapedmodel.find_all_by_local_id_and_retailer_id(local_id, ret.id).each do |sp|
            parse_and_set_attribute('averagereviewrating',rvu["averagereviewrating"], sp) if rvu["averagereviewrating"]
            parse_and_set_attribute('totalreviews', rvu['totalreviews'], sp) if rvu["totalreviews"]
            pid ||= sp.product_id
            sp.save
          end
          parse_and_set_attribute('product_id', pid, r) if pid and r
          r.save
          report_error "Review #{r.id} has nil product_id" if r and r.product_id.nil?
        end
      end
    end  
    announce "#{Review.count - total_before_script} reviews added."
    timed_announce "Done!"
    @logfile.close unless @logfile.closed?
  end
  
  task :rescrape_stats do 
    #att = 'itemwidth' # This will be re-scraped.
    atts = ['itemlength', 'itemwidth', 'itemheight']
    allproducts = Product.instock | Product.instock_ca # Product.all
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
          puts "Oops -- no scraped #{Session.current.product_type} from #{$retailers.first.name} for #{pid}"
        end
        
        retailer_ok_sps.each do |retailer_ok_sp|
          local_id = retailer_ok_sp.local_id
          retailer = Retailer.find(retailer_ok_sp.retailer_id)
          spid = retailer_ok_sp.id
          generic_scrape(local_id, retailer)
          unless atts.collect{|x| retailer_ok_sp[x]}.include?(nil)
            newvals ||= retailer_ok_sp.attributes
            puts "#{spid} has been fixed!"
            no_stats_fixed << pid
          end
          #end
        end
      end
      
      p = Product.find(pid)
      puts "Dims for #{pid} were: #{p.itemlength} x #{p.itemheight} x #{p.itemwidth}"
      avgs = vote_on_values(p)
      avgs.each{|name,val| parse_and_set_attribute(name, val, p)}
      p.save
      puts "Done #{pid}. New dims #{p.itemlength} x #{p.itemheight} x #{p.itemwidth}"
      #if newval and newval > 0 and newval < 7000
        #p = Session.current.product_type.find(pid)
        #atts.each{ |att| parse_and_set_attribute(att,newvals[att],p) } if newvals
      #end
      
    end
    puts "There were #{no_stats.count} printers w/o stats of which #{no_stats_fixed.count} were fixed"
  end
  
  task :validate_amazon => [:printer_init,:amazon_init, :validate_printers]
  
  task :camvote => [:cam_init,:vote]
  
  # The 2 things you can do, in terms of subtasks: scrape and update
  # task :scrape => [:scrape_new, :match_to_products, :update_bestoffers]
  task :update => [:update_prices, :scrape_new, :match_to_products, :update_specs, :update_bestoffers]
  
  task :endstuff => [:vote, :update_bestoffers]
  
  # Useful combinations of the above
  desc 'Get new prices and products from Newegg printers'
  task :update_newegg_printers => [:newegg_init, :update]
  
  desc 'Get new prices and products from TigerDirect printers'
  task :update_tiger_printers => [:tiger_init, :update]
  
  desc 'Get new prices and printers from Amazon'
  task :update_amazon_printers => [:printer_init, :amazon_init, :update]
  desc 'Get new products from Amazon (warning:extra long!)'
  task :update_amazon_printers_lph => [:laserprinterhub_init, :amazon_init, :update]
  desc 'Get new prices and cameras from Amazon'
  task :update_amazon_cameras => [:cam_init, :amazon_init, :update]
  
  desc 'Get new prices and products from Amazon Marketplace (printers)'
  task :update_amazon_mkt_printers => [:printer_init, :amazon_mkt_init, :update]
   
  desc 'Get new products from Amazon (warning:extra long!)'
  task :scrape_amazon_printers => [:printer_init, :amazon_init, :update_prices]
  
  desc 'Get new prices and products from Amazon cameras'
  task :scrape_amazon_cams => [:cam_init, :amazon_init, :scrape_new, :update_prices, :update_bestoffers]
  task :scrape_amazon_camera_retailer_offerings => [:cam_init, :amazon_init, :scrape_all]

  desc 'Get new products from Newegg'
  task :scrape_newegg_printers => [:newegg_init, :update]
  desc 'Get new products from TigerDirect'
  task :scrape_tiger_printers => [:tiger_init, :update]
    
  desc 'Get new printers from Amazon Marketplace (warning: extra long!)'
  task :scrape_amazon_mkt_printers => [:printer_init, :amazon_mkt_init, :update]
  desc 'Get new cameras from Amazon Marketplace (warning: extra long!)'
  task :update_amazon_mkt_cameras => [:cam_init, :amazon_mkt_init, :update]
  
  desc 'Get new prices and products from Amazon Marketplace (cameras)'
  
   # The subtasks...
  task :vote do 
    products = Product.all
    activerecords_to_save = []
    products.each do |p|
      avgs = vote_on_values(p)
      $bools_assume_no.each{|x| avgs[x] = false if avgs[x].nil?}
      #avgs.each do |k,v|
      #  puts "#{k} -- #{v} (now #{p.[](k)}) for #{p.id}" #if [v, p.[](k)].uniq.reject{|x| x.nil?}.length > 1
      #end
      avgs.each{|name,val| parse_and_set_attribute(name, val, p)}
      activerecords_to_save.push(p)
    end
    Product.transaction do
      activerecords_to_save.each(&:save)
    end
  end
  
  desc 'Match ScrapedPrinter to Printer!'
  task :match_to_products do
    @logfile = File.open("./log/#{just_alphanumeric($retailers.first.name)}_#{Session.current.product_type}_matcher.log", 'w+')
    puts "[#{Time.now}] Starting to match products"
    match_me = scraped_by_retailers($retailers, $scrapedmodel) if $retailers
    match_me = $scrapedmodel.all if match_me.nil?
        
    #puts "We have #{match_me.count} #{$scrapedmodel.name}s unmatched products."
    puts "We have #{match_me.count} products to match"
    
    match_me.delete_if{|x| (x.model.nil? and x.mpn.nil?) or x.brand.nil?}
    announce "#{match_me.count} #{$scrapedmodel.name}s are identifiable -- will match these."
    products = Product.find(:all, :conditions => ["product_type=?",Session.current.product_type])
    match_me.each_with_index do |scraped, i|
      matches = match_product_to_product(scraped, products, $series)
      announce "On Item " + i.to_s if i%10 == 0
      real = matches.first
      # If there is no product match, create a new product (and all the attributes).
      if real.nil?
        real = create_record_from_attributes(scraped.attributes)
        real.product_type = Session.current.product_type
        real.save # Because we need the ID below immediately
      end
      parse_and_set_attribute('product_id',real.id, scraped)
      scraped.save
      ros = find_ros_from_scraped(scraped, scraped.retailer_id)
      if ros.blank?
        column_names = RetailerOffering.column_names
        retail_offering_atts = scraped.attributes.reject{|r| not column_names.index(r)}
        ro = RetailerOffering.new(retail_offering_atts)
        ro.product_id = real.id
        ro.product_type = Session.current.product_type
        ro.priceint = ro.price if (ro.priceint.nil? && !(ro.price.nil?))
        ro.save
      end
      ros.each{ |ro| parse_and_set_attribute('product_id', real.id, ro); ro.save }     
      
      reviews = Review.find_all_by_local_id_and_product_type(scraped.local_id, Session.current.product_type)
      activerecords_to_save = []
      reviews.each do |review| 
        parse_and_set_attribute('product_id', real.id, review)
        activerecords_to_save.push(review)
      end
      Review.transaction do
        activerecords_to_save.each(&:save)
      end
    end
    timed_announce "[#{Time.now}] Done matching products"
    @logfile.close unless @logfile.closed?
  end
  
  task :update_specs do
    # Sometimes, there aren't enough continuous specs for some reason.
    # The symptom of this is that Product.valid is much lower than Product.instock.
    
    # For each product in the database, based on the product_type:
      # See what its specs are
      # If there are specs missing, attempt to add them. Do this by looking at the Scraped Model as appropriate.
    s = Session.current
    cont_spec_activerecords_to_save = []
    cat_spec_activerecords_to_save = []
    bin_spec_activerecords_to_save = []
    Product.find_all_by_product_type(s.product_type).each do |p|
      scraped_product = $scrapedmodel.find_by_product_id(p.id)
      next if scraped_product.nil?
      s.continuous["all"].each do |f|
        spec = ContSpec.find_by_name_and_product_id(f, p.id)
        if spec.nil?
          # there is a spec missing
          spec_value_dirty = scraped_product[f].to_f
          # clean it up
          # then store it
          spec_record = ContSpec.new({:product_type => s.product_type, :product_id => p.id, :name => f, :value => spec_value_dirty})
          cont_spec_activerecords_to_save.push(spec_record)
        end
      end

      s.categorical["all"].each do |f|
        spec = CatSpec.find_by_name_and_product_id(f, p.id)
        if spec.nil?
          # there is a spec missing
          spec_value_dirty = scraped_product[f].to_s
          # clean it up
          # then store it
          spec_record = CatSpec.new({:product_type => s.product_type, :product_id => p.id, :name => f, :value => spec_value_dirty})
          cat_spec_activerecords_to_save.push(spec_record)
        end
      end

      s.binary["all"].each do |f|
        spec = BinSpec.find_by_name_and_product_id(f, p.id)
        if spec.nil?
          # there is a spec missing
          spec_value_dirty = !(scraped_product[f].nil?)
          # clean it up
          # then store it
          spec_record = BinSpec.new({:product_type => s.product_type, :product_id => p.id, :name => f, :value => spec_value_dirty})
          bin_spec_activerecords_to_save.push(spec_record)
        end
      end

    end
    ContSpec.transaction do
      cont_spec_activerecords_to_save.each(&:save)
    end
    CatSpec.transaction do
      cat_spec_activerecords_to_save.each(&:save)
    end
    BinSpec.transaction do
      bin_spec_activerecords_to_save.each(&:save)
    end
  end
  
  # Update prices
  task :update_prices do
    filename = "./log/scrape/#{just_alphanumeric($retailers.first.name)}_#{Session.current.product_type}.log"
    @logfile = File.new(filename, 'w+') unless File.exist?(filename)
    @logfile = File.open(filename, 'w+') unless @logfile
    activerecords_to_save = []
    my_offerings = $retailers.inject([]){|r,x| r+RetailerOffering.find_all_by_retailer_id_and_product_type(x.id, Session.current.product_type)}
    my_offerings.each_with_index do |offering, i|
      next if offering.local_id.nil?
      newatts = rescrape_prices(offering.local_id, offering.region)
      # Validation!
      # There is a weird dollars/cents issue on the next line, hence multiplying by 100.
      if newatts['priceint'] and (newatts['priceint'].to_i > (100 * Session.current.maximumPrice))# or newatts['priceint'] < Session.current.minimumPrice)
        newatts['stock'] = false
        newatts['priceint'] = nil
      end

      update_offering(newatts, offering) if offering
      #if(offering.product_id and Session.current.product_type.exists?(offering.product_id))
      #  update_bestoffer(Session.current.product_type.find(offering.product_id))
      #end
      activerecords_to_save.push(offering)
      log "[#{Time.now}] Done updating #{i+1} of #{my_offerings.count} offerings"
    end
    RetailerOffering.transaction do
      activerecords_to_save.each(&:save)
    end

    timed_announce "Done updating retailer offerings"
    @logfile.close unless @logfile.closed?
  end

  # Scrape all data for all current products
  task :scrape_all do
    @logfile = File.open("./log/scrape/#{just_alphanumeric($retailers.first.name)}_#{Session.current.product_type}.log", 'w+')
    $retailers.each do |retailer|
      
      ids = scrape_all_local_ids retailer.region
      old_ids = (RetailerOffering.find_all_by_retailer_id(retailer.id)).collect{|x| x.local_id}
      ids = (ids + old_ids).uniq.reject{|x| x.nil?}
      
      announce "Will scrape #{ids.count} #{Session.current.product_type} from #{retailer.name}"
            
      ids.each_with_index do |local_id, i|
        generic_scrape(local_id, retailer)
        log "[#{Time.now}] Progress: done #{i+1} of #{ids.count} #{Session.current.product_type}s..."
      end
    end
    timed_announce "Done scraping"
    @logfile.close unless @logfile.closed?
  end
  
  # Scrape all data for new products only
  task :scrape_new do
    @logfile = File.open("./log/scrape/#{just_alphanumeric($retailers.first.name)}_#{Session.current.product_type}.log", 'w+')
    $retailers.each do |retailer|
      ids = scrape_all_local_ids(retailer.region)
      scraped_ids = ($scrapedmodel.find_all_by_retailer_id(retailer.id)).collect{|x| x.local_id}.uniq
      ids = (ids - scraped_ids).uniq.reject{|x| x.nil?}
      announce "Will scrape #{ids.count} #{Session.current.product_type} from #{retailer.name}, #{scraped_ids.count} already exist"
      
      ids.each_with_index do |local_id, i|
        generic_scrape(local_id, retailer)
        log "[#{Time.now}] Progress: done #{i+1} of #{ids.count} #{Session.current.product_type}..."
      end
    end
    timed_announce "Done scraping"
    @logfile.close unless @logfile.closed?
  end

  desc "Check that scraped data isn't wonky"
  task :validate_printers do
    require 'helpers/validation/data_validator'
    include DataValidator
    
    @logfile = File.open("./log/validate/#{just_alphanumeric($retailers.first.name)}_#{Session.current.product_type}.log", 'w+')
    
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
    @logfile.close unless @logfile.closed?
  end
  
  task :update_bestoffers do
    activerecords_to_save = []
    Product.find(:all, :conditions => ["product_type=?", Session.current.product_type]).each do |p|
      update_bestoffer(p)
      activerecords_to_save.push(p)
    end
    timed_announce "Done updating bestoffers; saving to database"
    Product.transaction do
      activerecords_to_save.each(&:save)
    end
  end

  task :cam_init => :init do
      include CameraHelper
      include CameraConstants
      
      s = Session.new("cameras")
      $AllSpecs = s.continuous["all"] + s.binary["all"] + s.categorical["all"]
      
      # TODO get rid of this construct:
      # It seems like there are some class variables being set ... instead of global variables?
      # Confusion. Try to take all of these out.
      
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

  task :laserprinterhub_init => :init do
    include PrinterHelper
    include LPHPrinterConstants

    s = Session.new("laserprinterhub.com")
    $AllSpecs = s.continuous["all"] + s.binary["all"] + s.categorical["all"]

    # TODO get rid of this construct:
    $scrapedmodel = @@scrapedmodel
    $brands= @@brands
    $series = @@series
    $descriptors = @@descriptors + $conditions.collect{|cond| /(\s|^|;|,)#{cond}(\s|,|$)/i}
    # \
    #  + $units.reject{|x| x=='in'}.collect{|y| /#{Regexp.escape(y)}/i}

    $reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'ppm', 'resolutionmax',\
       'paperinput','scanner', 'printserver', 'brand', 'model']
    $reqd_offering_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
       'local_id', "product_type", "region", "retailer_id"]
    $bools_assume_no = ['printserver', 'scanner']
  end

  task :printer_init => :init do
      include PrinterHelper
      include PrinterConstants
      
      s = Session.new("printers")
      $AllSpecs = s.continuous["all"] + s.binary["all"] + s.categorical["all"]
      
      # TODO get rid of this construct:
      $scrapedmodel = @@scrapedmodel
      $brands= @@brands
      $series = @@series
      $descriptors = @@descriptors + $conditions.collect{|cond| /(\s|^|;|,)#{cond}(\s|,|$)/i}
      # \
      #  + $units.reject{|x| x=='in'}.collect{|y| /#{Regexp.escape(y)}/i}
      
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
    require 'amazon/aws'
    require 'amazon/aws/search'
    include Amazon
  
    require 'nokogiri'
    include Nokogiri
  
    require 'helpers/sitespecific/amazon_scraper'
    include AmazonScraper
    
    # This is from web documentation. This is supposed to go with a Request.new
    # These parameters are in .amazonrc now.
    $ASSOCIATES_ID = 'ATVPDKIKX0DER'
    $ASSOCIATES_CA_ID = 'A3DWYIK6Y9EEQB'
    $KEY_ID = '0NHTZ9NMZF742TQM4EG2'
    $SECRET_KEY = 'WOYtAuy2gvRPwhGgj0Nz/fthh+/oxCu2Ya4lkMxO'
  
    $search_index = 'Electronics'
    $retailers = [Retailer.find(1)] # Retailer.find(8) -- this is amazon.ca
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
    database = config.database_configuration[Rails.env]["database"]
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
