namespace :sandbox do
  
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
    
    keep = $model.find(3308)
    ditch = $model.find(3218)
    
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
    debugger
    puts "#{keep.id} had bestoffer #{keep.bestoffer}"
    #update_bestoffer(keep)
    puts "#{keep.id} now has bestoffer #{$model.find(keep.id).bestoffer} (should be #{bestoffer_id})"
    debugger
    
  end
  
  task :remove_danglers => :environment do 
    require 'helper_libs'
   
    include CameraHelper
    include CameraConstants
    
    $model = @@model
    $scrapedmodel = @@scrapedmodel
    
    what = Review
    what.find_all_by_product_type($model.name).each do |ro|
      unless $model.exists?(ro.product_id) or ro.product_id.nil?
        ro.update_attribute('product_id', nil)
      end
    end
    
  end
  
  task :fix_links => :environment do 
    require 'helper_libs'
   
    include CameraHelper
    include CameraConstants
    
    $model = @@model
    $scrapedmodel = @@scrapedmodel
    
    ptype = $model.to_s
    
    what = Review
    #what.find_all_by_product_type($model.name).each do |ro|
    #  ro.update_attribute('product_id', nil)
    #end
    msgs = []
    $scrapedmodel.all.each do |sc|
      lid = sc.local_id
      rid = sc.retailer_id
      pid = sc.product_id
      unless pid.nil? or $model.exists?(pid)
        debugger
        0
      #  sc.update_attribute('product_id', nil)
      end
      
      if lid and rid# and pid
        ros = what.find_all_by_product_type_and_local_id_and_retailer_id(ptype,lid,rid)
        ros.each do |ro|
          if ro.product_id != pid
            
            if($model.find(pid).title == $model.find(ro.product_id).title or $model.find(ro.product_id).model.include?($model.find(pid).model))
              msgs << "Duplicate: #{pid} and #{ro.product_id}"
            else
              msgs << "#{ro.class.name} matched to #{ro.product_id}, which #{$model.exists?(ro.product_id) ? "exists" : "doesn't exist"}"
              msgs << "Want to change to #{pid}"
              #debugger
              #ro.update_attribute('product_id', pid)
              #puts "Changed to #{pid}"
            end
          end
        end
      end

    end
    puts "#{msgs.uniq * "\n"}"
  end
  
  task :fix_ptr_models => :environment do 
    require 'helper_libs'
   
    include GenericScraper    
    include ParsingLib
    include CleaningLib
    include LoggingLib
    include DatabaseLib
    include ScrapingLib
    
    include PrinterHelper
    include PrinterConstants
    
    $model = @@model
    $scrapedmodel = @@scrapedmodel
    $brands= @@brands
    $series = @@series
    $descriptors = @@descriptors
    
    $model.all.each do |ptr|
      atts = ptr.attributes
      modelsb4 = separate(atts['model']) + separate(atts['mpn'])
      moremodels = $scrapedmodel.find_all_by_product_id(ptr.id).collect{|x| [x.model, x.mpn]}.flatten.uniq
      modelsb4 += moremodels
      modelsb4 = modelsb4.sort{|a,b| likely_model_name(b) <=> likely_model_name(a) }.reject{|x| likely_model_name(x) < 2 }
      
      
      modelsafter = no_blanks( clean_models( $model.name, atts['brand'], \
            modelsb4, atts['title'],$brands, $series, $descriptors )).uniq.reject{|x| 
              likely_model_name(x) < 2 }.sort{|a,b| 
              likely_model_name(b) <=> likely_model_name(a)
      }
      atts['model'] = modelsafter[0]
      atts['mpn'] = modelsafter[1]
      if atts['model'] and atts['mpn'] and atts['model'].match(/#/)
        temp = atts['model']
        atts['model'] = atts['mpn']
        atts['mpn'] = temp
      end
      
      debugger unless atts['model']
      #puts "#{atts['model']} #{atts['mpn']}"
      ['model', 'mpn'].each do |x| 
        fill_in_forced(x,atts[x], ptr)
      end
      
      #puts "#{ptr['model']} #{ptr['mpn']}"
    end
    
  end
  
  task :fix_dims => :environment do 
    require 'helper_libs'
   
    include GenericScraper    
    include ParsingLib
    include CleaningLib
    include LoggingLib
    include DatabaseLib
    include ScrapingLib
    
    include PrinterHelper
    include PrinterConstants
    
    $model = @@model
    $scrapedmodel = @@scrapedmodel
    $brands= @@brands
    $series = @@series
    $descriptors = @@descriptors
    
    dimlabels = ['itemlength', 'itemwidth', 'itemheight']
    
    $model.all.each do |cam|
      avg_atts = {}
      best_dimset = dimlabels.collect{|x| cam[x]}
      #debugger
      if best_dimset and best_dimset != []
        dimlabels.size.times{ |i| avg_atts[dimlabels[i]] = best_dimset[i] } 
        str  = dims_to_s(avg_atts)
        #debugger
        cam.update_attribute('dimensions', str)
      else
        cam.update_attribute('dimensions', 'n/a') 
      end
    end
  end
  
  task :match_ros => :environment do 
    require 'helper_libs'
   
    include GenericScraper    
    include ParsingLib
    include CleaningLib
    include LoggingLib
    include DatabaseLib
    include ScrapingLib
    
    include CameraHelper
    include CameraConstants
    
    $model = @@model
    $scrapedmodel = @@scrapedmodel
    $brands= @@brands
    $series = @@series
    $descriptors = @@descriptors
    
    allros = RetailerOffering.find_all_by_product_type($model.name).reject{ |y|
      y.local_id.nil?
    }.collect{|x| x.id}
    
    count = 0
    
    puts "#{allros.count} total IDable ROs"
    
    allros.reverse.each do |roid|
      ro = RetailerOffering.find(roid)
      sps = $scrapedmodel.find_all_by_retailer_id_and_local_id(ro.retailer_id,ro.local_id)
      sp = sps.first
      if sp
        pid = sp.product_id
        count += 1
      end
      fill_in_forced('product_id', pid, ro)
    end
    puts "#{count} have been matched"
  end
  
  task :unmatch_reviews => :environment do 
    $model = Camera
    $scrapedmodel = ScrapedCamera
    
    matchme = Review.find_all_by_product_type('Camera').reject{|revu_id| !Review.exists?(revu_id)}
    
    count = 0
    matchme.each do |revu_id|      
      
      revu = Review.find(revu_id)
      
      next if revu.product_id.nil?
      next if revu.product_type != $model.name
      
      unless Camera.exists?(revu.product_id)
        #debugger if revu.product_type != 'Camera'
        #puts "#{revu.product_id}"
        #revu.update_attribute('product_id', nil)
        #puts "#{revu.product_id}"
        #debugger if revu.product_id
        count += 1
      end
      
      #puts "Review #{revu.id} : "
      #puts revu.summary
      #puts revu.content
      #lid =  revu['local_id']
      #sms = $scrapedmodel.find_all_by_local_id(lid)
      #sms.each do |sm|
        #puts "#{revu.id} matches #{$model.name} #{sm.product_id}, #{$model.find(sm.product_id).title}"
        
      #end
    end
    puts "Done unlinking #{count} revues"
  end
  
  task :fix_reviews => :environment do
    
      require 'helper_libs'

      include GenericScraper    
      include ParsingLib
      include CleaningLib
      include LoggingLib
      include DatabaseLib
      include ScrapingLib
      
      Review.all.each do |product|
        
        debugger if product.retailer_id
        fill_in('retailer_id', 1, product)
              
      end  
  end
  
  task :reorder_dims => :environment do
  
    require 'helper_libs'
    
    include GenericScraper    
    include ParsingLib
    include CleaningLib
    include LoggingLib
    include DatabaseLib
    
    $model = Camera
    $scrapedmodel = ScrapedCamera
    
    which_product_ids = Camera.all.collect{|x| x.id}
    
    dimlabels = ['itemlength', 'itemwidth', 'itemheight']
    
    which_product_ids.each do |pid| 
      sps = ScrapedCamera.find_all_by_product_id(pid)
      if sps.length != 0
        sps.each do |sp|
          atts = sp.attributes.reject{|a,b| !dimlabels.include?(a.to_s)}
          all_vals_to_s!(atts)
          rearrange_dims!(atts, ['D', 'H', 'W'], true)
          fill_in_all(atts,sp)
        end
      end
      p = Camera.find(pid)
      avgs = vote_on_values(p)
      fill_in_all(avgs, p)
    end
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
  
  task :find_dups => ['data:printer_init'] do
    
    matchings = get_matching_sets_efficient($model.all[0..10])
    puts( matchings.collect{|a| a * ', '} * "\n")
    
   # $model.all[0..100].each do |p|
      
      #x = $model.find_all_by_model(p.model || 'ABRACADABRA')
      #y =   $model.find_all_by_mpn(p.model || 'ABRACADABRA')
      #z = $model.find_all_by_model(p.mpn || 'ABRACADABRA')
      #w =   $model.find_all_by_mpn(p.mpn || 'ABRACADABRA')
      #dups = (x | y | z | w).uniq
      #if dups.length > 1
      #  #debugger
      #  puts "Found duplicates: #{dups.collect{|a| a.id} * ', '}"
      #end
   # end
    
  end
  
  task :test_fix_brands_ptr => ['data:printer_init', 'data:amazon_init', :test_fix_brands]
                              
  task :test_fix_brands_cam => ['data:cam_init', 'data:amazon_init', :test_fix_brands]
  
  task :test_fix_brands do
    fixme = $model.all
    changes = []
    fixme.each do |p|
      scraped_atts = p.attributes
      clean_atts = clean(scraped_atts)
      if "#{clean_atts['brand']}" !="#{p.brand}"
        puts "was: #{p.brand}"
        puts "will be: #{clean_atts['brand']}" if clean_atts
        changes << ["#{p.brand}", "#{clean_atts['brand']}"]
        #debugger
        #fill_in_forced('brand', clean_atts['brand'], p)
      end
    end
    changes_text = changes.uniq.collect{|a,b| "#{a} --> #{b}"}
    puts changes_text * "\n"
    
  end
  
  task :test_fix_models => ['data:cam_init', 'data:amazon_init'] do 
    
    fixme = $model.all
    fixme.each do |p|
      scraped_atts = p.attributes
      clean_atts = clean(scraped_atts)
      if "#{clean_atts['model']} and #{clean_atts['mpn']}" !="#{p.model} and #{p.mpn}"
        puts "was: #{p.model} and #{p.mpn}"
        puts "should be: #{clean_atts['model']} and #{clean_atts['mpn']}" if clean_atts
        #debugger
        fill_in_forced('model', clean_atts['model'], p)
        fill_in_forced('mpn', clean_atts['mpn'], p)
      end
    end
    
  end
    
end