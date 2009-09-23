# Scrape new-egg printers
# Abbreviations frequently used in var names: 
# ro : retailer offering
# no : newegg offering
# np : newegg printer
# npsd: newegg printer scraped data
# p  : printer
# o  : offering

namespace :scrape_newegg do
  
  desc "Update prices"
  task :update => :init do
    @logfile = File.open("./log/newegg_scraper.log", 'w+')
    my_offerings = $retailers.inject([]){|r,x| r+RetailerOffering.find_all_by_retailer_id(x.id)}
    my_oferings.each_with_index do |offering, i|
      begin
        newatts = rescrape_prices offering.local_id, offering.region
        log "Updating #{offering.pricestr} to #{newatts['pricestr']}"
        update_offering newatts, offering if offering
        update_bestoffer($model.find(offering.product_id)) if offering.product_id
      rescue Exception => e
        report_error "with RetailerOffering #{offering.id}:" + e.message.to_s + e.type.to_s
        sleep(20*60) # sleep for 20 min 
      end
      puts "Done updating #{i+1} of #{my_offerings.count} offerings"
    end
    
    @logfile.close
  end

  desc "Scrape model name from ids"
  task :scrape => :init do
    @logfile = File.open("./log/newegg_scraper.log", 'w+')
    
    $retailers.each do |retailer|
      next if retailer.region == 'us'
      ids = scrape_all_local_ids retailer.region
    
      ids.each_with_index do |item_number, i|
        begin
          scraped_atts = scrape item_number, retailer.region
          scraped_atts['local_id'] = item_number
          scraped_atts['product_type'] = $model.name
          scraped_atts['retailer_id'] = retailer.id
          scraped_atts['region'] = retailer.region
          clean_atts = clean scraped_atts
          

          # Should make this a method? 
          sp = find_or_create_scraped_printer(clean_atts)
          
          clean_atts['url'] = my_special_url (item_number, retailer.region)
          ros = find_ros_from_sp sp
          ro = ros.first
          
          ro = create_product_from_atts clean_atts, RetailerOffering if ro.nil?
          fill_in_all clean_atts, ro
          timestamp_offering ro
          
       rescue Exception => e  
          report_error "Error on #{i}th printer"
          report_error e.message.to_s + e.type.to_s
          sleep(20*60) # sleep for 20 min 
        end
        puts "Progress: done #{i+1} of #{ids.count} printers..."
      end
    end
    @logfile.close
  end
  
  desc 'validate'
  task :validate => :init do
    include ValidationHelper
    
    @logfile = File.open("./log/newegg_validation.log", 'w+')
    
    my_printers = sp_by_retailers($retailers)
    
    announce "Testing #{my_printers.count} ScrapedPrinters for validity..."
    
    reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'ppm', 'resolutionmax',\
       'paperinput','scanner', 'printserver', 'brand', 'model']
    reqd_fields.each do |rf|
      assert_no_nils my_printers, rf
    end   
    
    assert_no_repeats my_printers, 'local_id'
    
    assert_within_range my_printers, 'itemheight', 100, 10000
    assert_within_range my_printers, 'itemlength', 100, 7000
    assert_within_range my_printers, 'itemwidth', 100, 7000
    assert_within_range my_printers, 'ppm', 2, 50
    assert_within_range my_printers, 'paperinput', 20,2000
    assert_within_range my_printers, 'ttp', 7,40
    assert_within_range my_printers, 'resolutionmax', 600, 4800
    
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
  
  task :del_duplicates => :init do

  #    # Find all sets of IDs which describe the same printer
  #    all_dupl = []
  #    p_make_cols = ['brand']
  #    p_model_cols = ['model', 'mpn']
  #    counter = 0
  #    Printer.all.each do |p|
  #      dupl = duplicate_entries p_make_cols, p_model_cols, p
  #      if dupl.length > 1
  #        #puts "#{dupl.length} duplicates for #{p.id}: ids #{dupl * ', '}"   
  #        all_dupl << dupl.sort unless all_dupl.include? dupl.sort
  #        #counter += 1
  #      end
  #    end
  #    
  #    # Deal with duplicates
  #    all_dupl.each do |set|
  #      smallest = set[0]
  #      set.each do |x|
  #         # Find Amazon printer linked to duplicate
  #         ap = AmazonPrinter.find_by_product_id x
  #         if( !ap)
  #           puts "WARNING AmazonPrinter #{x} doesn't exist"
  #         elsif ( ap.product_id != smallest)
  #           # Re-link Amazon printer
  #           puts "will Change #{ap.id}'s product id from #{ap.product_id} to #{smallest}"
  #           ap.update_attribute('product_id', smallest)
  #           # Delete duplicate Printer
  #           puts "will Delete printer with id = #{x}."
  #           Printer.find(x).delete
  #         end
  #      end
  #      
  #    end
  #    
  #    puts "Num sets: #{all_dupl.length}. Num messages: #{counter}"
  #    
    end
  
  task :update_from_feed => :init do 
#    @logfile = File.open("./log/newegg_update.log", 'w+')
#    totally_new = 0 
#    feed_url = "http://www.newegg.com/Product/RSS.aspx?Submit=ENE&N=2000330630&ShowDeactivatedMark=True"
#    recent = get_recent_els_from_feed feed_url
#    
#    recent.each do |inum|
#     
#      no = RetailerOffering.find_by_local_id_and_retailer_id(inum, retailer.id)
#      begin
#        np = NeweggPrinter.find(no.printer_id) if no and no.printer_id
#        p = Printer.find(no.product_id) if no and no.product_id
#        o = RetailerOffering.find(no.offering_id) if no and no.offering_id
#      rescue
#        # do nothing
#      end
#            
#      if p.nil? or o.nil? # If the Printer or RetailerOffering entries are missing/not linked...
#        totally_new += 1
#        atts = scrape_all inum
#        np = no_and_np_from_atts atts, inum
#        p = map_to_db np
#        no = NeweggOffering.find_by_item_number(inum) if no.nil? 
#        o = RetailerOffering.find(no.offering_id) if no and no.offering_id
#        log "Something was missing but now we have printer #{p.id} and offering #{o.id}"
#      end
#      
#      report_error "No RetailerOffering matched with NeweggOffering!!" if o.nil?
#      
#      begin  
#        infopage = Nokogiri::HTML(open(id_to_details_url(inum)))
#        sleep(15)
#      rescue
#        report_error "Cant scrape #{inum}: #{id_to_details_url(inum)} doesnt' open"
#      else
#        params = scrape_prices infopage, inum
#        params = clean_prices params
#        update_offering params, o
#        log " Re-scraped prices for #{inum} ."
#      end
#      update_bestoffer p
#    end
#    puts "#{recent.count} in total"
#    puts "#{totally_new} completely new"
#   @logfile.close
    end
   
  task :duplicates => :init do
#    
#    puts "Checking NEWEGGPRINTERS for duplicates"
#    
#    np_make_cols = ['brand']
#    np_model_cols = ['model']
#    
#    ScrapedPrinter.all.each do |np|
#      dupl = duplicate_entries np_make_cols, np_model_cols, np
#      puts "#{dupl.length} duplicates for #{np.id}: ids #{dupl * ', '}"  if dupl.length > 1 
#    end
#    
#    puts "Checking PRINTERS for duplicates"
#    
#    p_make_cols = ['brand']
#    p_model_cols = ['model', 'mpn']
#    counter = 0
#    Printer.all.each do |p|
#      dupl = duplicate_entries p_make_cols, p_model_cols, p
#      puts "#{dupl.length-1} duplicates for #{p.id}: ids #{dupl * ', '}"  if dupl.length > 1 
#      counter += 1 if dupl.length > 1 
#    end
#    
#    puts "#{counter} duplicates detected.. may contain repeats"
  end
  
end