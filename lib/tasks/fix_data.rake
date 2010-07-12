namespace :fix_data do
  
  task :ptr_redo_endstuff  => ['data:printer_init', 'data:update_bestoffers']
  
  
  task :cam_rescrape  => ['data:cam_init', 'data:amazon_init', :rescrape_selected_2]
  
  task :cam_rescrape_mkt  => ['data:cam_init', 'data:amazon_mkt_init', :rescrape_selected]
  
  task :rescrape_selected_2 do 
    which_fields = ['itemweight']
    which_sp_ids = [4214, 4282, 4720, 4778, 4942, 5114, 5422, 5478, 5836, 5992, 6076] 
    
    retailerids = $retailers.collect{|x| x.id} 
    sps = which_sp_ids.collect{|x| $scrapedmodel.find(x)}
    retailer_ok_sps = sps.reject{|x| !retailerids.include?(x.retailer_id)}
    
    retailer_ok_sps.each do |retailer_ok_sp|
       local_id = retailer_ok_sp.local_id
       retailer = Retailer.find(retailer_ok_sp.retailer_id)
       spid = retailer_ok_sp.id
       
       debug = $scrapedmodel.find(spid)
       puts "#{local_id} had #{which_fields[0]} #{debug[which_fields[0]] || 'nil'}"
       which_fields.each do |fld|
         debug.update_attribute(fld, nil)
       end
       
       generic_scrape(local_id, retailer)
       
       debug = $scrapedmodel.find(spid) 
       puts "#{local_id} has #{which_fields[0]} #{debug[which_fields[0]] || 'nil'}"    
    end
    puts "Done"
  end
  
  task :rescrape_selected do 
    which_fields = ['itemweight']
    which_product_ids = []
    
    retailerids = $retailers.collect{|x| x.id} 
    
    which_product_ids.each do |pid| 
    
      sps = $scrapedmodel.find_all_by_product_id(pid)
      if sps.length != 0
        retailer_ok_sps = sps.reject{|x| !retailerids.include?(x.retailer_id)}
        if retailer_ok_sps.length == 0
          puts "Oops -- no scraped #{$product_type} from #{$retailers.first.name} for #{pid}"
        end
        
        retailer_ok_sps.each do |retailer_ok_sp|
          local_id = retailer_ok_sp.local_id
          retailer = Retailer.find(retailer_ok_sp.retailer_id)
          spid = retailer_ok_sp.id
          
          debug = $scrapedmodel.find(spid)
          puts "#{local_id} had #{which_fields[0]} #{debug[which_fields[0]] || 'nil'}"
          which_fields.each do |fld|
            debug.update_attribute(fld, nil)
          end
          
          generic_scrape(local_id, retailer)
          
          debug = $scrapedmodel.find(spid) 
          puts "#{local_id} has #{which_fields[0]} #{debug[which_fields[0]] || 'nil'}"    
        end
      end
      p = Product.find(pid, :conditions => ["product_type=?",$product_type])
      which_fields.each do |fld|
        p.update_attribute(fld, nil)
      end
      avgs = vote_on_values(p)
      fill_in_all avgs, p
      puts "Done #{pid}. New #{which_fields[0]} #{Product.find(pid, :conditions => ["product_type=?",$product_type])[which_fields[0]]}"
    end
    puts "Done"
  end

  # TODO this is temporary
  task :cam_rematch => ['data:cam_init', 'data:match_to_products']
  
  task :remove_danglers do 
    require 'helper_libs'
    
    what = Review
    what.find_all_by_product_type($product_type).each do |ro|
      unless Product.exists?(ro.product_id) or ro.product_id.nil?
        ro.update_attribute('product_id', nil)
      end
    end
    
  end
  
  task :links_2 => ['data:cam_init'] do 
    
    ptype = $product_type.to_s
    
    what = Review
    #what.find_all_by_product_type($product_type).each do |ro|
    #  ro.update_attribute('product_id', nil)
    #end
    msgs = []
    $scrapedmodel.all.each do |sc|
      lid = sc.local_id
      rid = sc.retailer_id
      pid = sc.product_id
      #unless pid.nil? or $product_type.exists?(pid)
      #  debugger
      #  0
      ##  sc.update_attribute('product_id', nil)
      #end
      
      if lid and rid and pid and Product.exists?(pid)
        ro_ids = what.find_all_by_product_type_and_local_id_and_retailer_id(ptype,lid,rid).collect{|x| x.id}
        ro_ids.each do |ro_id|
          ro = Review.find(ro_id)
          if( ro.product_id and ro.product_id != pid and Product.exists?(ro.product_id))
            keep = Product.find(pid, :conditions => ["product_type=?",$product_type])
            other = Product.find(ro.product_id, :conditions => ["product_type=?",$product_type])
            if other
              if(keep.title == other.title)# or keep.model.include?(other.model) or other.model.include?(keep.model))
                puts keep.title
                puts other.title
                unlink_duplicate(keep, other)
                puts "Unlinked #{other.id} -- replaced with #{keep.id}"
              end
            end
          end
        end
      end
    end
    puts "#{msgs.uniq * "\n"}"
  end
  
  task :links => :environment do 
    require 'helper_libs'
   
    include CameraHelper
    include CameraConstants
    
    $scrapedmodel = @@scrapedmodel
    
    ptype = $product_type.to_s
    
    what = Review
    #what.find_all_by_product_type($product_type).each do |ro|
    #  ro.update_attribute('product_id', nil)
    #end
    msgs = []
    $scrapedmodel.all.each do |sc|
      lid = sc.local_id
      rid = sc.retailer_id
      pid = sc.product_id
      unless pid.nil? or Product.exists?(pid)
        debugger
        0
      #  sc.update_attribute('product_id', nil)
      end
      
      if lid and rid# and pid
        ros = what.find_all_by_product_type_and_local_id_and_retailer_id(ptype,lid,rid)
        ros.each do |ro|
          if ro.product_id != pid
            product = Product.find(pid, :conditions => ["product_type=?",$product_type])
            retail_offering_product = Product.find(ro.product_id, :conditions => ["product_type=?",$product_type])
            if (product.title == retail_offering_product.title or retail_offering_product.model.include?(product.model))
              msgs << "Duplicate: #{pid} and #{ro.product_id}"
            else
              msgs << "#{ro.class.name} matched to #{ro.product_id}, which #{$product_type.exists?(ro.product_id) ? "exists" : "doesn't exist"}"
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
  
  task :ptr_models => :environment do 
    require 'helper_libs'
   
    include GenericScraper    
    include ParsingLib
    include CleaningLib
    include LoggingLib
    include DatabaseLib
    include ScrapingLib
    
    include PrinterHelper
    include PrinterConstants
    
    $scrapedmodel = @@scrapedmodel
    $brands= @@brands
    $series = @@series
    $descriptors = @@descriptors
    
    Product.all.each do |ptr|
      atts = ptr.attributes
      modelsb4 = separate(atts['model']) + separate(atts['mpn'])
      moremodels = $scrapedmodel.find_all_by_product_id(ptr.id).collect{|x| [x.model, x.mpn]}.flatten.uniq
      modelsb4 += moremodels
      modelsb4 = modelsb4.sort{|a,b| likely_model_name(b) <=> likely_model_name(a) }.reject{|x| likely_model_name(x) < 2 }
      
      
      modelsafter = clean_models( $product_type, atts['brand'], \
            modelsb4, atts['title'],$brands, $series, $descriptors ).uniq.compact.reject(&:blank?).reject{|x| 
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
  
  task :dims => :environment do 
    require 'helper_libs'
   
    include GenericScraper    
    include ParsingLib
    include CleaningLib
    include LoggingLib
    include DatabaseLib
    include ScrapingLib
    
    include PrinterHelper
    include PrinterConstants
    
    $scrapedmodel = @@scrapedmodel
    $brands= @@brands
    $series = @@series
    $descriptors = @@descriptors
    
    dimlabels = ['itemlength', 'itemwidth', 'itemheight']
    
    Product.all.each do |cam|
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
  
  task :pricehist => 'data:cam_init' do
    require 'yaml'
    ros = RetailerOffering.all.reject{|x| x.pricehistory.nil?}
    ros.each_with_index do |ro|
      hist = ro.pricehistory
      if hist and hist.match(/\n$/).nil?
        puts "#{ro.id} doesn't have newline at end of pricehist" 
        hist += "\n"
        fill_in('pricehistory', hist,ro)
        newhist = RetailerOffering.find(ro.id).pricehistory
        puts "#{ro.id} still doesn't have newline at end of pricehist" unless newhist and newhist.match(/\n$/).nil?
      end
      begin
        hist_obj = YAML::load(hist)
      rescue Exception => e
        puts "OOPS! #{e.message}"
      else
        next if hist_obj.class == Hash
        puts "Uh oh #{ro.id}"
        hist_hash = {}
        hist_obj.each_with_index do |x,i|
          next if i%2 == 1 
          hist_hash[hist_obj[i]]= hist_obj[i+1]
        end
        newhist_yaml = YAML::dump(hist_hash)
        debugger if newhist_yaml.match(/\n$/).nil?
        fill_in_forced('pricehistory', newhist_yaml, ro)
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
    
    $scrapedmodel = @@scrapedmodel
    $brands= @@brands
    $series = @@series
    $descriptors = @@descriptors
    
    allros = RetailerOffering.find_all_by_product_type($product_type).reject{ |y|
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
  
  # This function does not work at present (July 2010). Fix reviews as a block.
  task :unmatch_reviews => :environment do 
    $product_type = Camera # This construct needs to be taken out for reviews. First, review data needs to be separately processed.
    $scrapedmodel = ScrapedCamera
    
    matchme = Review.find_all_by_product_type('Camera').reject{|revu_id| !Review.exists?(revu_id)}
    
    count = 0
    matchme.each do |revu_id|      
      
      revu = Review.find(revu_id)
      
      next if revu.product_id.nil?
      next if revu.product_type != $product_type
      
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
        #puts "#{revu.id} matches #{$product_type} #{sm.product_id}, #{$product_type.find(sm.product_id).title}"
        
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
  
  task :revote_cam_stuff => ['data:cam_init', :revote_forced]
  
  task :revote_forced do
    stuff = ['itemlength', 'itemwidth', 'itemheight', 'dimensions']
    Product.all.each do |cam|
      newdims = vote_on_values(cam)
      stuff.each do |a|
        if cam[a] != newdims[a]
          fill_in_forced(a,newdims[a],cam)
        end
      end
    end
  end
  
  task :reorder_dims => :environment do
  
    require 'helper_libs'
    
    include GenericScraper    
    include ParsingLib
    include CleaningLib
    include LoggingLib
    include DatabaseLib
    
    $scrapedmodel = ScrapedCamera
    
    #which_product_ids = Camera.all.collect{|x| x.id}
    
    dimlabels = ['itemlength', 'itemwidth', 'itemheight']
    
    #which_product_ids.each do |pid| 
    #  sps = ScrapedCamera.find_all_by_product_id(pid)
    sps = ScrapedCamera.all
      if sps.length != 0
        sps.each do |sp|
          atts = sp.attributes.reject{|a,b| !dimlabels.include?(a.to_s)}
          all_vals_to_s!(atts)
          rearrange_dims!(atts, ['D', 'H', 'W'], true)
          dimlabels.each do |dim|
            fill_in_forced(dim,atts[dim], sp)
          end
        end
      end
      #p = Camera.find(pid)
      #avgs = vote_on_values(p)
      #fill_in_all(avgs, p)
   # end
  end

  task :rm_stupid_cam_prices => ['data:cam_init', :rm_stupid_prices]
  task :rm_stupid_ptr_prices => ['data:printer_init', :rm_stupid_prices]
  
  
  task :rm_stupid_prices do
    stupid = []
    ros  = RetailerOffering.find_all_by_product_type($product_type)
  
    ros.each do |ro|
      stupid << ro.id if ro.priceint and (ro['priceint'] > $MaximumPrice)
    end
   
    stupid.each do |x|
      xobj = RetailerOffering.find(x)
      fill_in('stock', false, xobj)
      fill_in_forced('priceint', nil, xobj)
    end
    
    puts "Done removing #{stupid.count} stupid prices"
  
  end
  
  task :test_ptr_brands => [:debug_mode, :fix_brands_ptr]
  task :test_cam_brands => [:debug_mode, :fix_brands_cam]
  task :ptr_brands => ['data:printer_init', 'data:amazon_init', :fix_brands]
  task :cam_brands => ['data:cam_init', 'data:amazon_init', :fix_brands]
  
  
  task :test_fix_models_ptr => [:debug_mode, :fix_models_ptr]
  task :test_fix_models_cam => [:debug_mode, :fix_models_cam]
  task :fix_models_ptr => ['data:printer_init', 'data:amazon_init', :fix_models]
  task :fix_models_cam => ['data:cam_init', 'data:amazon_init', :fix_models]
  
  task :debug_mode do
    $dry_run = true
  end
  
  task :fix_brands do
    [Product,$scrapedmodel].each do |model|
      announce "Fixing #{model.name}"
      fixme = model.all
      changes = []
      fixme.each do |p|
        scraped_atts = p.attributes
        clean_atts = clean(scraped_atts)
        if "#{clean_atts['brand']}" !="#{p.brand}"
          puts "was: #{p.brand}"
          puts "will be: #{clean_atts['brand']}" if clean_atts
          changes << ["#{p.brand}", "#{clean_atts['brand']}"]
          unless $dry_run
            fill_in_forced('brand', clean_atts['brand'], p)
          end
        end
      end
      changes_text = changes.uniq.collect{|a,b| "#{a} --> #{b}"}
      puts changes_text * "\n"
    end
  end
  
  task :fix_models  do
    model = Product
    announce "Fixing #{model.name}"
    fixme = model.all
    fixme.each do |p|
      scraped_atts = p.attributes
      clean_atts = clean(scraped_atts)
      if "#{clean_atts['model']} and #{clean_atts['mpn']}" !="#{p.model} and #{p.mpn}"
        puts "was: #{p.model} and #{p.mpn}"
        puts "should be: #{clean_atts['model']} and #{clean_atts['mpn']}" if clean_atts
        unless $dry_run
          fill_in_forced('model', clean_atts['model'], p)
          fill_in_forced('mpn', clean_atts['mpn'], p)
        end
      end
    end
  end
end
