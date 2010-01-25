module Check
  
  def chek_linkage check_me
    announce "Checking offering-#{$model.name.downcase} links"
    
    unlinked = []
    bad_linked = []
    
    ['', '_ca'].each do |prefix|
      check_me.each do |product|
        next unless product["instock#{prefix}"]
        if product.bestoffer.nil? 
          unlinked << product.id
        else
          offering = RetailerOffering.find(product["bestoffer#{prefix}"])
          bad_linked << product.id if offering.nil?
          bad_linked << product.id if offering.priceint != product["price#{prefix}"]
          bad_linked << product.id if offering["stock"] != product["instock#{prefix}"]
          bad_linked << product.id if offering.product_type != $model.name
          bad_linked << product.id if offering.product_id != product.id
        end
      end
    end
    
    unlinked.uniq!
    bad_linked.uniq!
    
    if unlinked.length > 0
      log_v "#{unlinked.count} #{$model.name}s are not linked"
      announce "First few: #{unlinked[0..5] * ', '} \n --- "
    end
    if bad_linked.length > 0
      log_v "#{bad_linked.count} #{$model.name}s are linked incorrectly."
      announce "First few: #{bad_linked[0..5] * ', '} \n --- "
    end
    
    announce "Done checking links"
  end
  
  def chek_products my_products
    announce "Testing #{my_products.count} #{$model.name}s for validity..."
    
    ($reqd_fields || []).each do |rf|
      assert_no_nils my_products, rf
    end
    
    assert_no_repeats(my_products, $id_field)
    assert_in_set(my_products, 'brand', $brands)
    assert_no_nils(my_products, 'brand')
    assert_no_nils(my_products, 'model')
    
    $model::ValidRanges.each do |k,v|
      assert_within_range( my_products, k, v[0], v[1])
    end
    
    bad_mdls = {}
    my_products.each do |product|
      ['model', 'mpn'].each do |mdl_field|
        mdl_value = product[mdl_field]
        if mdl_value
          mdl_quality = likely_model_name(mdl_value) 
          if mdl_quality < 2
            bad_mdls[mdl_value] = mdl_quality
          end
        end
      end
    end
    announce "#{bad_mdls.size} #{$model.name}s have bad id fields"
    if bad_mdls.size > 0
      announce "Poor models are: #{bad_mdls.keys * ', '}."
    end
    
    announce "Out of #{$model.count} #{$model.name}s... "
    announce " ... #{$model.valid.count} are valid"
    announce " ... #{($model.instock | $model.instock_ca).count} are in stock (in CA or US)"
    announce " ... #{($model.valid.instock | $model.valid.instock_ca).count} are valid and in stock"
    announce "Testing #{my_products.count} #{$model.name}s for wonky data..."
    
    announce "Done checking #{$model.name}s "
  end
  
  def chek_pictures checkme
    announce "Checking pictures for #{$model.name}s"
    nopix = 0
    noresized = 0
    brokenurls = 0
    nodims = 0
    checkme.each do |record|
      unless pic_exists(record)
        nopix += 1
      end
      unless resized_pics_exist(record)
        noresized += 1
      end
      unless pic_dimensions_exist( record)
        nodims += 1
      end
      unless pic_urls_not_broken( record)
        brokenurls += 1
      end
    end
    announce "#{nopix} of #{checkme.count} #{$model.name}s do not have a picture"
    announce "#{noresized} of #{checkme.count} #{$model.name}s do not have resized pix"
    announce "#{nodims} of #{checkme.count} #{$model.name}s do not have picture dimensions"
    announce "#{brokenurls} of #{checkme.count} #{$model.name}s have broken urls"
    announce "Done checking pictures"
  end
  
  def chek_offerings my_offerings
    timed_log "Start retailer offerings validation for #{$model.name}"
    announce "Testing #{my_offerings.count} RetailerOfferings for validity..."
    
    $reqd_offering_fields.each do |rf|
      assert_no_nils my_offerings, rf
    end
    
    Retailer.all.each do |ret|
      these_offerings = my_offerings.reject{|x| x.retailer_id != ret.id}
      assert_no_repeats these_offerings, 'local_id'
    end
   
    assert_within_range my_offerings, 'priceint', $model::MinPrice, $model::MaxPrice
    
    announce "Done checking offerings"
  end
end

namespace :check do
  
  task :cameras => [:cam_init, :products]
  task :printers => [:printer_init, :products]
  
  task :ro_and_r_links => :cam_init do 
    require 'helper_libs'
        
    include ParsingLib
    include LoggingLib
    
    ## Check link consistency
    #count1=0
    #count2=0
    #$model.all.each do |c|
    #  ros = RetailerOffering.find_all_by_product_type_and_product_id($model.name, c.id)
    #  rs = [] # Review.find_all_by_product_type_and_product_id($model.name, c.id)
    #  
    #  [ros, rs].flatten.each do |ro|
    #    lid = ro.local_id
    #    rid = ro.retailer_id
    #    sc = $scrapedmodel.find_by_retailer_id_and_local_id(rid,lid)
    #    if sc and sc.product_id != ro.product_id
    #      puts "Link not consistent for #{ro.class.name} #{ro.id}"
    #      #debugger
    #      count2 += 1
    #    elsif sc.nil?
    #      puts "#{ro.class.name} #{ro.id} (#{ro.stock ? '' : 'not'} in stock) has no corresponding SC"        
    #      #debugger
    #      count1 += 1
    #    end
    #  end
    #end
    #puts "#{count1} have no matching SC, #{count2} have inconsistent link"
    
    # Check link consistency 2
    count=0
    RetailerOffering.find_all_by_product_type($model.name).each do |ro|
      rid = ro.retailer_id
      lid = ro.local_id
      rs = Review.find_all_by_product_type_and_local_id($model.name, lid)
      pids_rside = rs.collect{|x| x.product_id}.uniq
      pids_roside = [ro.product_id]
      if pids_rside != pids_roside
        puts "Link not consistent for offer #{ro.id} and corresponding revues!"
        count +=1
      end
    end
    puts "#{count} inconsistent links..."
    
    count = 0
    RetailerOffering.find_all_by_product_type($model.name).each do |ro|
      unless $model.exists?(ro.product_id) or ro.product_id.nil?
        count += 1
        puts "#{ro.id} is a dangler -- #{$model.name} #{ro.product_id} doesnt exist"
      end
    end
    puts "#{count} offerings are danglers"
    
    count = 0
    Review.find_all_by_product_type($model.name).each do |ro|
      unless $model.exists?(ro.product_id) or ro.product_id.nil?
        count += 1
        puts "#{ro.id} is a dangler -- #{$model.name} #{ro.product_id} doesnt exist"
      end
    end
    puts "#{count} reviews are danglers"
  end
  
  task :sc_to_c_links => :cam_init do 
    
    require 'helper_libs'
        
    include ParsingLib
    include LoggingLib
    
    ScrapedCamera.all.each do |sc|
      next unless sc.product_id
      unless Camera.exists?(sc.product_id)
         #report_error "No match found for #{sc.id}"
         next
      end
      
      c = Camera.find(sc.product_id)
      if c.brand != sc.brand
        #debugger
        puts "#{c.brand} VS #{sc.brand}"
        report_error "Brand not matched for c-sc #{c.id} <--> #{sc.id}"
      end
      
      mm_c = [c.model, c.mpn].collect{|x| just_alphanumeric(x)}
      mm_sc = [sc.model, sc.mpn].collect{|x| just_alphanumeric(x)}
      if (mm_sc & mm_c).length < 1
        ok = false
        mm_sc.each{|el|
          mm_c.each{|el2|
            ok = (ok or (el.match(/#{el2}/)) or (el2.match(/#{el}/))) if el and el2
          }
        }
        unless ok
          puts "#{mm_c * ', '} VS #{mm_sc * ', '} "
          report_error "Model not matched for c-sc #{c.id} <--> #{sc.id}" 
        end
      end
    end
  end
  
  task :reviews => :init do 
    
    require 'helper_libs'
    include DatabaseLib
    
    chekme = Review.all.collect{|x| x.id}
    unidentifiable = []
    blank = []
    unlinked = []
    badlinked = []
    badlinked_2 = []
    
    chekme.each do |revu_id|
      revu = Review.find(revu_id)
      unidentifiable << revu_id unless review_is_recognizable?( revu)
      blank << revu_id unless ((revu['content'] and revu['content'].to_s.strip != '') or revu['rating'])
      if ( revu.product_type || '').to_s != '' and (revu.product_id)
        mdl = revu.product_type.constantize
        if mdl
          begin
             product = mdl.find(revu.product_id)
          rescue ActiveRecord::RecordNotFound => e
             product = nil # Record not found!
          end
          
          
          badlinked << revu_id unless product
          if revu.local_id
            scrapeds = "Scraped#{mdl}".constantize.find_all_by_product_id(revu.product_id)
            scrapeds.each do |scr|
              if scr.local_id and scr.local_id != revu.local_id
                badlinked_2 << [revu_id, scr.id]
              end
            end
          end
        else
          badlinked << revu_id 
        end
      else
        unlinked << revu_id
      end
    end
    
    puts "#{blank.count} blank reviews"
    puts "#{unidentifiable.count} non-identifiable reviews"
    puts "#{unlinked.count} reviews not linked"
    puts "#{badlinked.count} incorrectly linked review-product pairs"
    puts "#{badlinked_2.count} incorrectly linked review-scraped pairs"
    
  end
    
  task :products do
    include ValidationLib
    require 'helpers/image_helper'
    include ImageHelper
    include ImageValidator
    
    @logfile = File.open("./log/check_#{$model.name}.log", 'a+')
    timed_log 'Start camera-specific validation'
    my_products = $model.all
   # my_valid_products = $model.valid.instock  | $model.valid.instock_ca
    my_offerings = RetailerOffering.find_all_by_product_type_and_stock($model.name, true)
    
    chek_linkage(my_products)
    
    chek_offerings(my_offerings)
    
    chek_products(my_products)
        
    @logfile.close
  end
  
  task :pictures do
    require 'helpers/image_helper'
    include ImageHelper
    include ImageValidator
    
    checkme = $model.instock | $model.instock_ca
    chek_pictures checkme
  end
  
  task :printer_init => [:init, 'data:printer_init' ] do
      $id_field = 'id'
      
      $product_series = $printer_series
      $reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'ppm', 'resolutionmax',\
         'paperinput','scanner', 'printserver', 'brand', 'model']
      $reqd_offering_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
         'local_id', "product_type", "region", "retailer_id"]
  end
  
  task :cam_init => [:init, 'data:cam_init' ] do    
      $id_field = 'id'
      $reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'opticalzoom', 'maximumresolution', \
        'displaysize', 'brand', 'model', 'itemweight'] 
        # 'slr', 'waterproof', 
        # , 'imagesurl', 'imagemurl', 'imagelurl'
      $reqd_offering_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
         'local_id', "product_type", "region", "retailer_id"]
  end
  
  task :init => :environment do 
    require 'validation_libs'
    include ValidationLib
    include Check
  end    
  
end