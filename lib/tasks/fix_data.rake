namespace :fix_data do
  
  task :cam_rescrape  => ['data:cam_init', 'data:amazon_init', :rescrape_selected_2]
  
  task :cam_rescrape_mkt  => ['data:cam_init', 'data:amazon_mkt_init', :rescrape_selected]
  
  task :rescrape_selected_2 do 
    which_fields = ['itemweight']
    which_sp_ids = [4214, 4282, 4720, 4778, 4942, 5114, 5422, 5478, 5836, 5992, 6076] 
    #[3590, 3904, 3948, 4200, 4448, 4522, 4672, 4712, 4774, 5188, 5244, 5302, 5400, 5484, 5486, 5506, 5534, 5540, 5754, 5788, 5950, 6112, 6182, 6262, 6308, 6422, 6494, 7224, 7292, 7430, 7556, 7574, 7594, 7812, 7852, 8012, 8094, 8112, 8214, 8492, 8820, 8922, 9150, 9290, 9628, 9822, 9950, 10048, 10148, 10184, 10458, 10702, 10704, 10706, 10760, 10874, 10876, 10970, 11000, 11006, 11126, 11188, 11302, 11546, 11558, 11634, 11660, 11786, 11830, 12600, 12626, 12790, 13062, 13202, 13254, 13356, 13364, 13378, 13406, 13456, 13560, 13800, 13834, 13908, 13918, 13946, 13948, 14084, 14136, 14144, 14222, 14316, 14362, 14390, 14616, 14700, 14744, 14772, 14776, 14874, 14928, 14952, 15096, 15106, 15210, 15268, 15318, 15382, 15432, 15462, 15570, 15628, 15656, 15660, 15690, 15722, 15738, 15752, 15754, 15776, 15820, 15870, 15976, 16044, 16058, 16272, 16316, 16362, 16376, 16450, 16522, 16524, 16542, 16560, 16566, 16770, 16786, 16830, 16900, 17020, 17132, 17150, 17222, 17264, 17370, 17444, 17846, 18150, 18194, 18220, 18284, 18476, 18576, 18646, 18736, 18954, 18988, 19064, 19068, 19078, 19112, 19140, 19188, 19242, 19552, 19588, 19648, 19652, 19662, 19690, 19696, 19854, 19868, 19904, 20008, 20028, 20062, 20296, 20340, 20382, 20400, 20526, 20534, 20602, 20642, 20724, 20836, 20874, 20954, 20962, 21256, 21280, 21322, 21332, 21362, 21386, 21400, 21424, 21500, 21560, 21572, 21578, 21804, 21806, 21814, 21892, 21900, 21916, 21936, 22142, 22210, 22268, 22296, 22348, 22376, 22492, 22800, 22980, 23192, 23194, 23242, 23400, 23420, 23480, 23608, 23656, 23740, 23798, 23866, 23898, 23934, 23938, 23964, 24094, 24258, 24324, 24334, 24354, 24356, 24492, 24544, 24556, 24596, 24640, 25172, 25194, 25312, 25318, 25472, 25602, 25642, 25676, 25690, 25700, 25740, 25800, 25808]
    
    # PROBLEM: 3278
      #, 3294, 
    #[2232, 2326, 2440, 2464, 2834, 2928, 3042, 3066, 3278, 3424, 3646, 3830, 4052, 4116, 4158, 4260, 4580, 4692, 4698, 4934, 5314, 5762, 5772, 5906, 6034, 6556, 7420, 7650, 7882, 8032, 8224, 8388, 8592, 8600, 8784, 9152, 9402, 9466, 9510, 9616, 9986, 10018, 10064, 10312, 10720, 11146, 11156, 11278, 11430, 11916, 12762, 12976, 12994, 13056, 13434, 13946, 14084, 14136, 14144, 14222, 14316, 14362, 14616, 14700, 14744, 14776, 14874, 14952, 15096, 15106, 15268, 15382, 15432, 15462, 15628, 15660, 15690, 15738, 15752, 15776, 15870, 15976, 16044, 16376, 16450, 16786, 16830, 17020, 17846, 18576, 18988, 19112, 19140, 19188, 19652, 19696, 19854, 19868, 19904, 20008, 20028, 20296, 20340, 20382, 20526, 20534, 20602, 20642, 20724, 20874, 21256, 21280, 21322, 21362, 21400, 21424, 21572, 21804, 21806, 22210, 22980, 23608, 23740, 23798, 23938, 24022, 24148, 24258, 24324, 24334, 24354, 24492, 24640, 25172, 25194, 25676, 25740, 25800]
    
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
    #['maximumresolution']
    #['displaysize']
    #['itemlength', 'itemwidth', 'itemheight']
    which_product_ids = []
    #[740, 888, 1388, 1404, 1412, 1674, 1734, 1774, 1776, 1792, 1812, 1864, 1872, 1878, 1964, 1972, 1982, 1996, 2024, 2078, 2098, 2106, 2108, 2118, 2130, 2144, 2162, 2166, 2168, 2174, 2180, 2228, 2316, 2330, 2384, 2386, 2388, 2410, 2492, 2500, 2620, 2658, 2666, 2670, 2674, 2724, 2726, 2770, 2802, 2806, 2810, 2832, 2844, 2854, 2858, 2868, 2870, 2876, 2898, 2932, 2938, 2946, 3000, 3004, 3006, 3016, 3026, 3034, 3046, 3056, 3098, 3132, 3148, 3160, 3188, 3192, 3212, 3214, 3218, 3262, 3284, 3316, 3338, 3368, 3388, 3424, 3432, 3436, 3468, 3476, 3502, 3570, 3652, 3840, 3846, 3870, 3874, 3894, 3896, 3910, 3912, 3936, 3948, 3986, 4008, 4012, 4052, 4056, 4060, 4086, 4088, 4092, 4094, 4098, 4108, 4114, 4126, 4128, 4134, 4144, 4156, 4168, 4172, 4198, 4202, 4214, 4278, 4280, 4298, 4306, 4372, 4374, 4376, 4396, 4420, 4430, 4438, 4446, 4454, 4456, 4474, 4478, 4480, 4486, 4496, 4500, 4540, 4548, 4560, 4564, 4576, 4578, 4584, 4612, 4638, 4658, 4660, 4672, 4706, 4750, 4760, 4766, 4838, 4840, 4934, 4936, 4942, 4948, 4950, 4952, 4956, 4958, 4960, 4974, 4978, 5000, 5044, 5102, 5106, 5144, 5162, 5276, 5432, 5436, 5440, 5442, 5580, 6092, 6100, 6110, 6112, 6136, 6148, 6158, 6164, 6170, 6182, 6208, 6224]
    #[320, 338, 442, 478, 570, 620, 752, 1006, 1312, 1440, 1456, 1542, 1604, 1828, 1914, 1938, 2086, 2140, 2234, 2244, 2248, 2280, 2346, 2434, 2448, 2484, 2490, 2556, 2736, 2742, 2812, 2860, 2958, 3222, 3306, 3342, 3512, 3860, 4004, 4122, 4342, 4650, 4680, 4784, 4820, 4860, 5060, 5080, 5446, 5538, 5594, 5622, 5710, 5792, 5840, 5974, 5980, 6146, 6154, 6174, 6190, 6192, 6220]
    
    retailerids = $retailers.collect{|x| x.id} 
    
    which_product_ids.each do |pid| 
    #puts "Camera #{pid}: #{$model.find(pid).title}"
    #puts "Current resolution #{$model.find(pid).maximumresolution}"
    
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
      p = $model.find(pid)
      which_fields.each do |fld|
        p.update_attribute(fld, nil)
      end
      avgs = vote_on_values(p)
      fill_in_all avgs, p
      puts "Done #{pid}. New #{which_fields[0]} #{$model.find(pid)[which_fields[0]]}"
    end
    puts "Done"
  end

  # TODO this is temporary
  task :cam_rematch => ['data:cam_init', 'data:match_to_products']
  
  task :remove_danglers do 
    require 'helper_libs'
    
    what = Review
    what.find_all_by_product_type($model.name).each do |ro|
      unless $model.exists?(ro.product_id) or ro.product_id.nil?
        ro.update_attribute('product_id', nil)
      end
    end
    
  end
  
  task :fix_links_2 => ['data:cam_init'] do 
    
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
      #unless pid.nil? or $model.exists?(pid)
      #  debugger
      #  0
      ##  sc.update_attribute('product_id', nil)
      #end
      
      if lid and rid and pid and $model.exists?(pid)
        ro_ids = what.find_all_by_product_type_and_local_id_and_retailer_id(ptype,lid,rid).collect{|x| x.id}
        ro_ids.each do |ro_id|
          ro = Review.find(ro_id)
          if( ro.product_id and ro.product_id != pid and $model.exists?(ro.product_id))
            keep = $model.find(pid)
            other = $model.find(ro.product_id)
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
  
  task :fix_pricehist => 'data:cam_init' do
    require 'yaml'
    ros = RetailerOffering.all.reject{|x| x.pricehistory.nil?}
    ros.each_with_index do |ro|
      hist = ro.pricehistory
      puts "#{ro.id}" if hist and hist.match(/\n$/).nil?
      hist += "\n" if hist and hist.match(/\n$/).nil?
      #debugger if hist != ro.pricehistory
      fill_in('pricehistory', hist,ro)
      #debugger
      begin
        hist_obj = YAML::load(hist)
      rescue Exception => e
        debugger
        0
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
  
  task :revote_cam_stuff => ['data:cam_init', :revote_forced]
  
  task :revote_forced do
    stuff = ['itemlength', 'itemwidth', 'itemheight', 'dimensions']
    $model.all.each do |cam|
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
    
    $model = Camera
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
  
  task :test_fix_brands_ptr => [:debug_mode, :fix_brands_ptr]
  task :test_fix_brands_cam => [:debug_mode, :fix_brands_cam]
  task :fix_brands_ptr => ['data:printer_init', 'data:amazon_init', :fix_brands]
  task :fix_brands_cam => ['data:cam_init', 'data:amazon_init', :fix_brands]
  
  
  task :test_fix_models_ptr => [:debug_mode, :fix_models_ptr]
  task :test_fix_models_cam => [:debug_mode, :fix_models_cam]
  task :fix_models_ptr => ['data:printer_init', 'data:amazon_init', :fix_models]
  task :fix_models_cam => ['data:cam_init', 'data:amazon_init', :fix_models]
  
  task :debug_mode do
    $dry_run = true
  end
  
  task :fix_brands do
    [$model,$scrapedmodel].each do |model|
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
    [$model].each do |model| # [$model,$scrapedmodel].each do |model|
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
    
end