module Check
  
  #def csv_names_row
  #  first =  ['data set', 'total', 'brand', 'model/mpn']
  #  #second = Session.current.product_type::Features.collect{|x| x[0]}
  #  #third = ['itemheight', 'itemwidth', 'itemlength']
  #  validitable = Session.current.product_type::ValidRanges.keys
  #  retme = first + validitable + ['priceint']
  #  return retme
  #end
  
  
  def csv_names_row
    first =  ['data set', 'total', 'wacky brand', 'nil brand', 'nil model']
    validitable = Session.current.product_type::ValidRanges.keys
    retme = (first + validitable.collect{|x| ["nils in #{x}", "0s in #{x}", "#{x} out of range"]}).flatten
    return retme
  end
  
  def csv_row my_products, dataset_name='' 
    array = [dataset_name, my_products.count]
    
    array << count_not_in_set(my_products, 'brand', $brands)
    array << count_nils(my_products, 'brand')
    array << count_nils(my_products, 'model')
    
    Session.current.product_type::ValidRanges.each do |k,v|
      array << count_nils( my_products, k)
      array << count_0_values( my_products, k)
      array << count_not_in_range( my_products, k, v[0], v[1])
    end
    
    return array
  end
  
  def check_linkage check_me
    announce "Checking offering-#{Session.current.product_type} links"
    
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
          bad_linked << product.id if offering.product_type != Session.current.product_type
          bad_linked << product.id if offering.product_id != product.id
        end
      end
    end
    
    unlinked.uniq!
    bad_linked.uniq!
    
    if unlinked.length > 0
      log_v "#{unlinked.count} #{Session.current.product_type}s are not linked"
      announce "First few: #{unlinked[0..5] * ', '} \n --- "
    end
    if bad_linked.length > 0
      log_v "#{bad_linked.count} #{Session.current.product_type}s are linked incorrectly."
      announce "First few: #{bad_linked[0..5] * ', '} \n --- "
    end
    
    announce "Done checking links"
  end
  
  def check_products my_products
    announce "Testing #{my_products.count} #{Session.current.product_type}s for validity..."
    
    ($reqd_fields || []).each do |rf|
      assert_no_nils my_products, rf
    end
    
    assert_no_repeats(my_products, $id_field)
    assert_in_set(my_products, 'brand', $brands)
    assert_no_nils(my_products, 'brand')
    assert_no_nils(my_products, 'model')
    
    Session.current.product_type::ValidRanges.each do |k,v|
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
    announce "#{bad_mdls.size} #{Session.current.product_type}s have bad id fields"
    if bad_mdls.size > 0
      announce "Poor models are: #{bad_mdls.keys * ', '}."
    end
    
    announce "Out of #{Session.current.product_type.count} #{Session.current.product_type}s... "
    announce " ... #{Session.current.product_type.valid.count} are valid"
    announce " ... #{(Session.current.product_type.instock | Session.current.product_type.instock_ca).count} are in stock (in CA or US)"
    announce " ... #{(Session.current.product_type.valid.instock | Session.current.product_type.valid.instock_ca).count} are valid and in stock"
    announce "Testing #{my_products.count} #{Session.current.product_type}s for wonky data..."
    
    announce "Done checking #{Session.current.product_type}s "
  end
  
  def check_pictures checkme
    announce "Checking pictures for #{Session.current.product_type}s"
    nopix = 0
    noresized = 0
    brokenurls = 0
    nodims = 0
    checkme.each do |record|
      unless file_exists_for(record[id], '')
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
    announce "#{nopix} of #{checkme.count} #{Session.current.product_type}s do not have a picture"
    announce "#{noresized} of #{checkme.count} #{Session.current.product_type}s do not have resized pix"
    announce "#{nodims} of #{checkme.count} #{Session.current.product_type}s do not have picture dimensions"
    announce "#{brokenurls} of #{checkme.count} #{Session.current.product_type}s have broken urls"
    announce "Done checking pictures"
  end
  
  def check_offerings my_offerings
    timed_log "Start retailer offerings validation for #{Session.current.product_type}"
    announce "Testing #{my_offerings.count} RetailerOfferings for validity..."
    
    $reqd_offering_fields.each do |rf|
      assert_no_nils my_offerings, rf
    end
    
    Retailer.all.each do |ret|
      these_offerings = my_offerings.reject{|x| x.retailer_id != ret.id}
      assert_no_repeats these_offerings, 'local_id'
    end
    
    my_offerings.each do |ro|
      hist = ro.pricehistory
      if hist
        if hist.match(/\n$/).nil?
          report_error "#{ro.id} has malformed price history (missing newline)" 
        else
           begin
              hist_obj = YAML::load(hist)
           rescue Exception => e
              report_error "Problem loading #{ro.id}'s price history: #{e.class.name} #{e.message}"
           else
             report_error "#{ro.id} price history not a hash" if hist_obj.class != Hash
           end
        end
      end
    end
   
    assert_within_range my_offerings, 'priceint', Session.current.minimumPrice, Session.current.maximumPrice
    
    announce "Done checking offerings"
  end
end

namespace :check do
  
  task :cam_csv => [:cam_init, :csv]
  task :ptr_csv => [:printer_init, :csv]
  
  task :cameras => [:cam_init, :products]
  task :printers => [:printer_init, :products]
  
  task :ro_and_r_links => :cam_init do 
    require 'helper_libs'
        
    include ParsingLib
    include LoggingLib
    
    ## Check link consistency
    #count1=0
    #count2=0
    #Product.all.each do |c|
    #  ros = RetailerOffering.find_all_by_product_type_and_product_id(Session.current.product_type, c.id)
    #  rs = [] # Review.find_all_by_product_type_and_product_id(Session.current.product_type, c.id)
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
    RetailerOffering.find_all_by_product_type(Session.current.product_type).each do |ro|
      rid = ro.retailer_id
      lid = ro.local_id
      rs = Review.find_all_by_product_type_and_local_id(Session.current.product_type, lid)
      pids_rside = rs.collect{|x| x.product_id}.uniq
      pids_roside = [ro.product_id]
      if pids_rside != pids_roside
        puts "Link not consistent for offer #{ro.id} and corresponding revues!"
        count +=1
      end
    end
    puts "#{count} inconsistent links..."
    
    count = 0
    RetailerOffering.find_all_by_product_type(Session.current.product_type).each do |ro|
      unless Session.current.product_type.exists?(ro.product_id) or ro.product_id.nil?
        count += 1
        puts "#{ro.id} is a dangler -- #{Session.current.product_type} #{ro.product_id} doesnt exist"
      end
    end
    puts "#{count} offerings are danglers"
    
    count = 0
    Review.find_all_by_product_type(Session.current.product_type).each do |ro|
      unless Session.current.product_type.exists?(ro.product_id) or ro.product_id.nil?
        count += 1
        puts "#{ro.id} is a dangler -- #{Session.current.product_type} #{ro.product_id} doesnt exist"
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
    
  task :csv do 
    include ValidationLib
    
    config   = Rails::Configuration.new
    database = config.database_configuration[Rails.env]["database"]
    
    @logfile = File.open("./log/check/#{database}_#{Session.current.product_type}.csv", 'w')
    @logfile.puts(csv_names_row*", ")
    
    x = csv_row Product.all, 'all'
    @logfile.puts(x * ", ")
    x = csv_row Product.valid, 'valid'
    @logfile.puts(x * ", ")
    x = csv_row (Product.instock|Product.instock_ca), 'in stock'
    @logfile.puts(x * ", ")
    x = csv_row (Product.instock.valid|Product.instock_ca.valid), 'valid & instock'
    @logfile.puts(x * ", ")
    x = csv_row (Product.all-Product.valid), 'invalid'
    @logfile.puts(x * ", ")
    
    @logfile.close
  end  
    
  task :products do
    include ValidationLib
    require 'helpers/image_helper'
    include ImageHelper
    include ImageValidator
    
    @logfile = File.open("./log/check/#{Session.current.product_type}.log", 'a+')
    timed_log 'Start camera-specific validation'
    my_products = Product.all
    my_valid_products = Session.current.product_type.valid.instock  | Session.current.product_type.valid.instock_ca
    my_offerings = RetailerOffering.find_all_by_product_type_and_stock(Session.current.product_type, true)
    
    check_linkage(my_products)
    
    check_offerings(my_offerings)
    
    check_products(my_valid_products)
        
    @logfile.close
  end
  
  task :pictures do
    require 'helpers/image_helper'
    include ImageHelper
    include ImageValidator
    
    checkme = Session.current.product_type.instock | Session.current.product_type.instock_ca
    check_pictures checkme
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