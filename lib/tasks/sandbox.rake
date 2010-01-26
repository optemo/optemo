namespace :sandbox do
  
  task :check_new_voting =>  ['data:cam_init']  do 
    # Get weirdo weight cams
    #weirdos =# Camera.all.reject{|x| x['itemweight'].nil? or x['itemweight'] <= Camera::ValidRanges['itemweight'][1]}
    dims = ['itemheight', 'itemlength', 'itemwidth']
    weirdos = $model.all.reject{|x| 
      dims.inject(false){|d| !x[d].nil? and x[d] == 0}
    }
    debugger
    weirdos.each do |cam|
      temp = vote_on_values(cam)
      temp2 = {}
      temp.each do |k,v| 
        temp2[k] = cam[k]
      end
      temp.each do |k,v|
        fill_in_forced(k,v,cam)
      end
      puts "Done!"
    end
    
  end
  
  task :clean_dims =>  ['data:cam_init']  do 
    bad = $model.all.reject{|x| 
      dims.inject(false){|d| !x[d].nil? and x[d] == 0}
    }
    debugger
    bad.each do |b|
      fill_in_forced(b,'')
    end
  end
  
  task :test_remove_dups => :environment do
    include GenericScraper
    $model = Printer
    $scrapedmodel = ScrapedPrinter
    require 'rubygems'
    require 'nokogiri'

    require 'helper_libs'
    
    include GenericScraper    
    include ParsingLib
    include CleaningLib
    include LoggingLib
    include DatabaseLib
    include ScrapingLib
    
    keep = $model.find(2)
    ditch = $model.find(4228)
    
    puts "#{ditch.title} to be merged with #{keep.title}."
    
    sps_keep = $scrapedmodel.find_all_by_product_id(keep.id)
    sps_ditch = $scrapedmodel.find_all_by_product_id(ditch.id)
    puts "These #{$scrapedmodel.name}s will be re-routed: #{sps_ditch.collect{|x| x.id} *', '}"
    
    ros_keep = RetailerOffering.find_all_by_product_id_and_product_type(keep.id, $model.name)
    ros_ditch = RetailerOffering.find_all_by_product_id_and_product_type(ditch.id, $model.name)
    puts "These ROs will be re-routed: #{ros_ditch.collect{|x| x.id} *', '}"
    
    revus_keep = Review.find_all_by_product_id_and_product_type(keep.id, $model.name)
    revus_ditch = Review.find_all_by_product_id_and_product_type(ditch.id, $model.name)
    puts "These Reviews will be re-routed: #{revus_ditch.collect{|x| x.id} *', '}"
    
    bestoffer_id = (ros_keep+ros_ditch).sort{|a,b| (a.priceint || 1000000) <=> (b.priceint  || 1000000)}.first.id 
    
    # Lets see what they are
    debugger
        
    unlink_duplicate(keep, ditch)

    sps_keep_2 = $scrapedmodel.find_all_by_product_id(keep.id)
    sps_ditch_2 = $scrapedmodel.find_all_by_product_id(ditch.id)
    
    ros_keep_2 = RetailerOffering.find_all_by_product_id_and_product_type(keep.id, $model.name)
    ros_ditch_2 = RetailerOffering.find_all_by_product_id_and_product_type(ditch.id, $model.name)
    
    revus_keep_2 = Review.find_all_by_product_id_and_product_type(keep.id, $model.name)
    revus_ditch_2 = Review.find_all_by_product_id_and_product_type(ditch.id, $model.name)
    
    puts "#{sps_ditch_2.count} (SPs) should be 0"
    puts "#{ros_ditch_2.count} (ROs) should be 0"
    puts "#{revus_ditch_2.count} (Reviews) should be 0"
    
    puts "#{sps_keep_2.count} (SPs) should be #{sps_keep.count+sps_ditch.count}"
    puts "#{ros_keep_2.count} (ROs) should be #{ros_keep.count+ros_ditch.count}"
    puts "#{revus_keep_2.count} (Reviews) should be #{revus_keep.count+revus_ditch.count}"
    
    puts "#{$model.exists?(ditch.id)} should be false"
    
    # Lets see what they are again
    puts "#{keep.id} had bestoffer #{keep.bestoffer}"
    #update_bestoffer(keep)
    puts "#{keep.id} now has bestoffer #{$model.find(keep.id).bestoffer} (should be #{bestoffer_id})"
    
  end
  
  task :validate => :environment do 
    require 'helpers/parsing/idfields'
    require 'helpers/parsing/strings'
    require 'helpers/global_constants'
    include Constants
    include PrinterConstants
    include IdFieldsHelper
    include StringCleaner
    
    $model = @@model
    $series = @@series
    $brands = @@brands
    
    
    id_able = @@scrapedmodel.all.reject{|x|  (x.model.nil? or x.mpn.nil?) 
      }.reject{|y| likely_model_name(y.model) < 2 or likely_model_name(y.mpn) < 2 }
    
    puts "#{@@model.count} total, with #{@@scrapedmodel.count} scraped"
    puts "#{id_able.count} of #{@@scrapedmodel.count} identifiable"
    
  end
  
  task :test_remove_all_dups => ['data:printer_init'] do
    timed_announce "Starting to look for matching sets"
    matchings = get_matching_sets_efficient($model.all)
    timed_announce "Done looking for matching sets"
    puts "#{matchings.count} sets of duplicates"
    puts "#{matchings.flatten.count - matchings.count} duplicates will be removed"
    matchings.each do |set|
      skipthis = false
      bestoffer_id = nil
      puts "\n---\n#{set.collect{|y| Printer.find(y).title} * "\n"}\n---\n"
      debugger
      next if skipthis
      
      keep = $model.find(set[0])
      set[1..-1].each do |ditch_id|
        ditch = $model.find(ditch_id)
        puts "#{ditch.title} to be merged with #{keep.title}."
        
        sps_keep = $scrapedmodel.find_all_by_product_id(keep.id)
        sps_ditch = $scrapedmodel.find_all_by_product_id(ditch.id)
        puts "These #{$scrapedmodel.name}s will be re-routed: #{sps_ditch.collect{|x| x.id} *', '}"
      
        ros_keep = RetailerOffering.find_all_by_product_id_and_product_type(keep.id, $model.name)
        ros_ditch = RetailerOffering.find_all_by_product_id_and_product_type(ditch.id, $model.name)
        puts "These ROs will be re-routed: #{ros_ditch.collect{|x| x.id} *', '}"
      
        revus_keep = Review.find_all_by_product_id_and_product_type(keep.id, $model.name)
        revus_ditch = Review.find_all_by_product_id_and_product_type(ditch.id, $model.name)
        puts "These Reviews will be re-routed: #{revus_ditch.collect{|x| x.id} *', '}"
        bestoffer_id = (ros_keep+ros_ditch).sort{|a,b| (a.priceint || 1000000) <=> (b.priceint  || 1000000)}.first.id 
      
        unlink_duplicate(keep, ditch)
      
        sps_keep_2 = $scrapedmodel.find_all_by_product_id(keep.id)
        sps_ditch_2 = $scrapedmodel.find_all_by_product_id(ditch.id)
      
        ros_keep_2 = RetailerOffering.find_all_by_product_id_and_product_type(keep.id, $model.name)
        ros_ditch_2 = RetailerOffering.find_all_by_product_id_and_product_type(ditch.id, $model.name)
      
        revus_keep_2 = Review.find_all_by_product_id_and_product_type(keep.id, $model.name)
        revus_ditch_2 = Review.find_all_by_product_id_and_product_type(ditch.id, $model.name)
      
        puts "#{sps_ditch_2.count} (SPs) should be 0"
        puts "#{ros_ditch_2.count} (ROs) should be 0"
        puts "#{revus_ditch_2.count} (Reviews) should be 0"
      
        puts "#{sps_keep_2.count} (SPs) should be #{sps_keep.count+sps_ditch.count}"
        puts "#{ros_keep_2.count} (ROs) should be #{ros_keep.count+ros_ditch.count}"
        puts "#{revus_keep_2.count} (Reviews) should be #{revus_keep.count+revus_ditch.count}"
      
        puts "#{$model.exists?(ditch.id)} should be false"
      
      end
      
      puts "#{keep.id} had bestoffer #{keep.bestoffer}"
      update_bestoffer(keep)
      puts "#{keep.id} now has bestoffer #{$model.find(keep.id).bestoffer} (should be #{bestoffer_id})"
    end
      
  end
  
  task :test_amazon_cache => ['data:printer_init', :amazon_efficient_mkt_init] do
    
    $retailers.each do |ret|
      start = Time.now
      mycache = open_cache(ret)
      time = Time.now - start
      puts "Took #{time} seconds to get #{ret.name} #{$model.name} cache"
      nokocache = Nokogiri::HTML(mycache)
      # Test num available items
      num_items = nokocache.css('item').count
      puts "#{num_items} items in #{ret.name} cache"
      debugger
      my_offerings = RetailerOffering.find_all_by_retailer_id_and_product_type(ret.id, $model.name).reject{|x| x.local_id.nil?}[2..5]
     #my_offerings = ['B001XUQP9G', 'B0006UGKUI', 'B000XZ1LJG', 'B0027ISA1Y'].collect{|x| RetailerOffering.find_by_local_id_and_product_type(x, $model.name)}.reject{|x| x.nil?}
      my_offerings.each do |offering|
          next if offering.local_id.nil?
          newatts = rescrape_prices(offering.local_id, ret.region)
          puts "Was it toolow? #{newatts['toolow']}"
          puts "Was it in stock? #{newatts['stock']}"
          puts "Price will be #{newatts['pricestr']}"
          deciphered = (decipher_retailer( newatts['merchant'], newatts['region']))
          puts "The new RO appears to be from #{deciphered} (should be from #{ret.name})"
          puts "Now please check availability for #{id_to_details_url( offering.local_id, ret.region)}"
          puts "Should be #{newatts['availability']}"
          debugger 
          0
      end
    end
    #puts "Done"
  end
  
  
  
  task :test_redo_amazon_cache => ['data:printer_init', :amazon_efficient_init] do
    
    $retailers.each do |ret|
      start = Time.now
      mycache = refresh_cache(ret)
      time = Time.now - start
      puts "Took #{time} seconds to get #{ret.name} #{$model.name} cache"
      nokocache = Nokogiri::HTML(mycache)
    end
    #puts "Done"
  end
  
  task :time_amazon_update => ['data:printer_init', :amazon_efficient_init, :update_timer]
  
  task :update_timer do
    #num_to_update = 10_000
    my_offerings = $retailers.inject([]){|r,x| r+RetailerOffering.find_all_by_retailer_id_and_product_type(x.id, $model.name)}#[1..num_to_update]
    num_to_update = my_offerings.count
    
    time = Time.now
    my_offerings.each_with_index do |offering, i|
      #begin
        next if offering.local_id.nil?
        newatts = rescrape_prices(offering.local_id, offering.region)
        
        update_offering(newatts, offering) if offering
        if(offering.product_id and $model.exists?(offering.product_id))
          update_bestoffer($model.find(offering.product_id))
        end  
      #rescue Exception => e
      #  report_error "with RetailerOffering #{offering.id}: #{e.class.name} #{e.message}"
      #  sleep(1) # Do not skew timing results
      #end
      log "[#{Time.now}] Done updating #{i+1} of #{my_offerings.count} offerings"
    end
    
    time = Time.now - time
    puts "Took #{time} seconds to get #{num_to_update} offerings"
  end
  
  task :amazon_efficient_mkt_init => :amazon_efficient_init do
    $retailers = [Retailer.find(2),Retailer.find(10)]
  end
  
  task :amazon_efficient_init do
    require 'amazon/ecs'
    include Amazon
    
    require 'nokogiri'
    include Nokogiri
    
    require 'helpers/sitespecific/amazon_scraper_efficient' # Difference here.
    include AmazonScraper
    
    Amazon::Ecs.options = { :aWS_access_key_id => '0NHTZ9NMZF742TQM4EG2', \
                            :aWS_secret_key => 'WOYtAuy2gvRPwhGgj0Nz/fthh+/oxCu2Ya4lkMxO'}
    
    AmazonID =   'ATVPDKIKX0DER'
    AmazonCAID = 'A3DWYIK6Y9EEQB'
    
    $search_index = 'Electronics'
    $retailers = [Retailer.find(1),Retailer.find(8)]
  end
  
end