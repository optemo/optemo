namespace :sandbox do
  
  task :ptr_rm_idjunk => ['data:printer_init',:idfields_rm_junk]
  
  task :cam_rm_idjunk => ['data:cam_init',:idfields_rm_junk]
  
  task :parse_c_log => :environment do
    logName = "log/sample1.log"
    file = File.open(logName, 'r')
      while (line = file.gets)
       if line.include? "#{Time.now.year}-"     
         timeLine = line
         verLine = file.gets
         endLine = file.gets
         while endLine and (endLine.include? "layer")
            endLine = file.gets   
         end    
       end
      end
    debugger 
    file.close
  end
  
  task :idfields_rm_junk do
    activerecords_to_save = []
    Product.all.each do |product|
      ids = {'model' => product.model, 'mpn' => product.mpn}
      $descriptors.each do |d|
        ids.each do |idname,idval|
          next if idval.nil?
          if idval.match(d)
            puts "#{idval} has #{d}" 
            parse_and_set_attribute(idname,nil,product)
            activerecords_to_save.push(product)
          end
        end
      end
    end
    Product.transaction do
      activerecords_to_save.each(&:save)
    end
  end
  
  task :check_new_voting =>  ['data:cam_init']  do 
    # Get weirdo weight cams
    #weirdos =# Camera.all.reject{|x| x['itemweight'].nil? or x['itemweight'] <= Camera::ValidRanges['itemweight'][1]}
    dims = ['itemheight', 'itemlength', 'itemwidth']
    weirdos = Product.all.reject{|x| 
      dims.inject(false){|d| !x[d].nil? and x[d] == 0}
    }
    debugger
    activerecords_to_save = []
    weirdos.each do |cam|
      temp = vote_on_values(cam)
      temp2 = {}
      temp.each do |k,v| 
        temp2[k] = cam[k]
      end
      temp.each do |k,v|
        parse_and_set_attribute(k,v,cam)
      end
      puts "Done!"
      activerecords_to_save.push(cam)
    end
    Product.transaction do
      activerecords_to_save.each(&:save)
    end
  end
  
  task :clean_dims =>  ['data:cam_init']  do 
    bad = Product.all.reject{|x| 
      dims.inject(false){|d| !x[d].nil? and x[d] == 0}
    }
    debugger
    bad.each do |b|
      parse_and_set_attribute(b,'') # This doesn't work and I'm not sure what was intended. The arguments to parse_and_set_attribute are (key,value,record)
    end
  end
  
  task :test_remove_dups => :environment do
    include GenericScraper
    $product_type = Printer
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
    
    keep = $product_type.find(2)
    ditch = $product_type.find(4228)
    
    puts "#{ditch.title} to be merged with #{keep.title}."
    
    sps_keep = $scrapedmodel.find_all_by_product_id(keep.id)
    sps_ditch = $scrapedmodel.find_all_by_product_id(ditch.id)
    puts "These #{$scrapedmodel.name}s will be re-routed: #{sps_ditch.collect{|x| x.id} *', '}"
    
    ros_keep = RetailerOffering.find_all_by_product_id_and_product_type(keep.id, $product_type)
    ros_ditch = RetailerOffering.find_all_by_product_id_and_product_type(ditch.id, $product_type)
    puts "These ROs will be re-routed: #{ros_ditch.collect{|x| x.id} *', '}"
    
    revus_keep = Review.find_all_by_product_id_and_product_type(keep.id, $product_type)
    revus_ditch = Review.find_all_by_product_id_and_product_type(ditch.id, $product_type)
    puts "These Reviews will be re-routed: #{revus_ditch.collect{|x| x.id} *', '}"
    
    bestoffer_id = (ros_keep+ros_ditch).sort{|a,b| (a.priceint || 1000000) <=> (b.priceint  || 1000000)}.first.id 
    
    # Lets see what they are
    debugger
        
    unlink_duplicate(keep, ditch)

    sps_keep_2 = $scrapedmodel.find_all_by_product_id(keep.id)
    sps_ditch_2 = $scrapedmodel.find_all_by_product_id(ditch.id)
    
    ros_keep_2 = RetailerOffering.find_all_by_product_id_and_product_type(keep.id, $product_type)
    ros_ditch_2 = RetailerOffering.find_all_by_product_id_and_product_type(ditch.id, $product_type)
    
    revus_keep_2 = Review.find_all_by_product_id_and_product_type(keep.id, $product_type)
    revus_ditch_2 = Review.find_all_by_product_id_and_product_type(ditch.id, $product_type)
    
    puts "#{sps_ditch_2.count} (SPs) should be 0"
    puts "#{ros_ditch_2.count} (ROs) should be 0"
    puts "#{revus_ditch_2.count} (Reviews) should be 0"
    
    puts "#{sps_keep_2.count} (SPs) should be #{sps_keep.count+sps_ditch.count}"
    puts "#{ros_keep_2.count} (ROs) should be #{ros_keep.count+ros_ditch.count}"
    puts "#{revus_keep_2.count} (Reviews) should be #{revus_keep.count+revus_ditch.count}"
    
    puts "#{$product_type.exists?(ditch.id)} should be false"
    
    # Lets see what they are again
    puts "#{keep.id} had bestoffer #{keep.bestoffer}"
    #update_bestoffer(keep)
    puts "#{keep.id} now has bestoffer #{$product_type.find(keep.id).bestoffer} (should be #{bestoffer_id})"
    
  end
  
  task :validate => :environment do 
    require 'helpers/parsing/idfields'
    require 'helpers/parsing/strings'
    require 'helpers/global_constants'
    include Constants
    include PrinterConstants
    include IdFieldsHelper
    include StringCleaner
    
    $product_type = @@model
    $series = @@series
    $brands = @@brands
    
    
    id_able = @@scrapedmodel.all.reject{|x|  (x.model.nil? or x.mpn.nil?) 
      }.reject{|y| likely_model_name(y.model) < 2 or likely_model_name(y.mpn) < 2 }
    
    puts "#{@@model.count} total, with #{@@scrapedmodel.count} scraped"
    puts "#{id_able.count} of #{@@scrapedmodel.count} identifiable"
    
  end
  
  task :rm_ptr_dups => ['data:printer_init', :remove_dups, 'data:update_bestoffers']
  
  task :rm_cam_dups => ['data:cam_init', :remove_dups, 'data:update_bestoffers']
  
  task :remove_dups do
    timed_announce "Starting to look for matching sets"
    matchings = get_matching_sets_efficient
    timed_announce "Done looking for matching sets"
    puts "#{matchings.count} sets of duplicates"
    puts "#{matchings.flatten.count - matchings.count} duplicates will be removed"
    matchings.each_with_index do |set,i|
      keep = $product_type.find(set[0])
      set[1..-1].each do |ditch_id|
        ditch = $product_type.find(ditch_id)
        unlink_duplicate(keep, ditch)
      end
      timed_announce "Done #{i+1}/#{matchings.count}"
    end
      
  end
  
  task :test_remove_all_dups => ['data:printer_init'] do
    timed_announce "Starting to look for matching sets"
    matchings = get_matching_sets_efficient
    timed_announce "Done looking for matching sets"
    puts "#{matchings.count} sets of duplicates"
    puts "#{matchings.flatten.count - matchings.count} duplicates will be removed"
    matchings.each do |set|
      skipthis = false
      bestoffer_id = nil
      puts "\n---\n#{set.collect{|y| Printer.find(y).title} * "\n"}\n---\n"
      debugger
      next if skipthis
      
      keep = $product_type.find(set[0])
      set[1..-1].each do |ditch_id|
        next unless $product_type.exists?(ditch_id)
        ditch = $product_type.find(ditch_id)
        puts "#{ditch.title} to be merged with #{keep.title}."
        
        sps_keep = $scrapedmodel.find_all_by_product_id(keep.id)
        sps_ditch = $scrapedmodel.find_all_by_product_id(ditch.id)
        puts "These #{$scrapedmodel.name}s will be re-routed: #{sps_ditch.collect{|x| x.id} *', '}"
      
        ros_keep = RetailerOffering.find_all_by_product_id_and_product_type(keep.id, $product_type)
        ros_ditch = RetailerOffering.find_all_by_product_id_and_product_type(ditch.id, $product_type)
        puts "These ROs will be re-routed: #{ros_ditch.collect{|x| x.id} *', '}"
      
        revus_keep = Review.find_all_by_product_id_and_product_type(keep.id, $product_type)
        revus_ditch = Review.find_all_by_product_id_and_product_type(ditch.id, $product_type)
        puts "These Reviews will be re-routed: #{revus_ditch.collect{|x| x.id} *', '}"
        bestoffer_id = (ros_keep+ros_ditch).sort{|a,b| (a.priceint || 1000000) <=> (b.priceint  || 1000000)}.first.id 
      
        unlink_duplicate(keep, ditch)
      
        sps_keep_2 = $scrapedmodel.find_all_by_product_id(keep.id)
        sps_ditch_2 = $scrapedmodel.find_all_by_product_id(ditch.id)
      
        ros_keep_2 = RetailerOffering.find_all_by_product_id_and_product_type(keep.id, $product_type)
        ros_ditch_2 = RetailerOffering.find_all_by_product_id_and_product_type(ditch.id, $product_type)
      
        revus_keep_2 = Review.find_all_by_product_id_and_product_type(keep.id, $product_type)
        revus_ditch_2 = Review.find_all_by_product_id_and_product_type(ditch.id, $product_type)
      
        puts "#{sps_ditch_2.count} (SPs) should be 0"
        puts "#{ros_ditch_2.count} (ROs) should be 0"
        puts "#{revus_ditch_2.count} (Reviews) should be 0"
      
        puts "#{sps_keep_2.count} (SPs) should be #{sps_keep.count+sps_ditch.count}"
        puts "#{ros_keep_2.count} (ROs) should be #{ros_keep.count+ros_ditch.count}"
        puts "#{revus_keep_2.count} (Reviews) should be #{revus_keep.count+revus_ditch.count}"
      
        puts "#{$product_type.exists?(ditch.id)} should be false"
      
      end
      
      puts "#{keep.id} had bestoffer #{keep.bestoffer}"
      update_bestoffer(keep)
      keep.save
      puts "#{keep.id} now has bestoffer #{$product_type.find(keep.id).bestoffer} (should be #{bestoffer_id})"
    end
      
  end
  
  task :test_amazon_cache => ['data:printer_init', 'data:amazon_mkt_init'] do
    
    $retailers.each do |ret|
      start = Time.now
      mycache = open_cache(ret)
      time = Time.now - start
      puts "Took #{time} seconds to get #{ret.name} #{$product_type} cache"
      nokocache = Nokogiri::HTML(mycache)
      # Test num available items
      num_items = nokocache.css('item').count
      puts "#{num_items} items in #{ret.name} cache"
      debugger
      my_offerings = RetailerOffering.find_all_by_retailer_id_and_product_type(ret.id, $product_type).reject{|x| x.local_id.nil?}[2..5]
     #my_offerings = ['B001XUQP9G', 'B0006UGKUI', 'B000XZ1LJG', 'B0027ISA1Y'].collect{|x| RetailerOffering.find_by_local_id_and_product_type(x, $product_type)}.reject{|x| x.nil?}
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
  
  
  
  task :test_redo_amazon_cache => ['data:printer_init', 'data:amazon_init'] do
    
    $retailers.each do |ret|
      start = Time.now
      mycache = refresh_cache(ret)
      time = Time.now - start
      puts "Took #{time} seconds to get #{ret.name} #{$product_type} cache"
      nokocache = Nokogiri::HTML(mycache)
    end
    #puts "Done"
  end
  
  task :time_amazon_update => ['data:cam_init', 'data:amazon_init', :update_timer]
  
  task :update_timer do
    num_to_update = 50
    my_offerings = $retailers.inject([]){|r,x| r+RetailerOffering.find_all_by_retailer_id_and_product_type(x.id, $product_type)}[1..num_to_update]
    #num_to_update = my_offerings.count
    
    time = Time.now
    activerecords_to_save = []
    my_offerings.each_with_index do |offering, i|
      begin
        next if offering.local_id.nil?
        newatts = rescrape_prices(offering.local_id, offering.region)
        
        update_offering(newatts, offering) if offering
        activerecords_to_save.push(offering)
        #if(offering.product_id and $product_type.exists?(offering.product_id))
        #  update_bestoffer($product_type.find(offering.product_id))
        #end  
      rescue Exception => e
        report_error "with RetailerOffering #{offering.id}: #{e.class.name} #{e.message}"
        sleep(1) # Do not skew timing results
      end
      log "[#{Time.now}] Done updating #{i+1} of #{my_offerings.count} offerings"
    end
    RetailerOffering.transaction do
      activerecords_to_save.each(&:save)
    end
    time = Time.now - time
    puts "Took #{time} seconds to get #{num_to_update} offerings"
  end
  
  
end