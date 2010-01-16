namespace :sandbox do
  
  task :check_cam2s => :environment do 
  
    puts Camera2.count
  
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
    
    matchings = get_matching_sets_efficient($model.all)
    puts( matchings[0..10].collect{|a| a * ', '} * "\n")
    debugger
    puts "#{matchings.count} sets of duplicates"
    puts "#{matchings.flatten.count - matchings.count} duplicates will be removed"
    
  end
  
end