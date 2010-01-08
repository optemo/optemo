module Check
  
  def chek_linkage check_me
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
  end
  
  def chek_products my_products
    announce "Testing #{my_products.count} #{$model.name} for validity..."
    
    ($reqd_fields || []).each do |rf|
      assert_no_nils my_products, rf
    end
    
    assert_no_repeats my_products, $id_field
    
    announce "Out of #{$model.count} #{$model.name}s... "
    announce " ... #{$model.valid.count} are valid"
    announce " ... #{($model.instock | $model.instock_ca).count} are in stock (in CA or US)"
    announce " ... #{($model.valid.instock | $model.valid.instock_ca).count} are valid and in stock"
    timed_log 'Done general product validation'
  end
  
  def chek_pictures checkme
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
    puts "#{nopix} of #{checkme.count} #{$model.name}s do not have a picture"
    puts "#{noresized} of #{checkme.count} #{$model.name}s do not have resized pix"
    puts "#{nodims} of #{checkme.count} #{$model.name}s do not have picture dimensions"
    puts "#{brokenurls} of #{checkme.count} #{$model.name}s have broken urls"
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
   
    assert_within_range my_offerings, 'priceint', $min_price, $max_price
  end
end

namespace :check do
  
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
    
  task :cameras => [:cam_init] do #, :pictures] do
    include ValidationLib
    require 'helpers/image_helper'
    include ImageHelper
    include ImageValidator
    
    @logfile = File.open("./log/check_#{$model.name}_2.log", 'a+')
    timed_log 'Start camera-specific validation'
    my_products = $model.instock | $model.instock_ca
    my_valid_products = $model.valid.instock  | $model.valid.instock_ca
    my_offerings = RetailerOffering.find_all_by_product_type_and_stock($model.name, true)
    
    #chek_pictures(my_products)
    #chek_offerings(my_offerings)
    #chek_products(my_products)
    #chek_linkage(my_products)
    
    announce "Testing #{my_valid_products.count} valid #{$model.name}s for wonky data..."
    
    assert_within_range( my_valid_products, 'itemheight', 200, 450)
    assert_within_range( my_valid_products, 'itemlength', 60, 350) # depth
    assert_within_range( my_valid_products, 'itemwidth', 350, 600)
                             
    assert_within_range( my_valid_products, 'maximumresolution', 0.5, 50)    
    assert_within_range( my_valid_products, 'opticalzoom', 1, 26)
    assert_within_range( my_valid_products, 'displaysize', 0.5, 4)
    
    assert_within_range( my_valid_products, 'price', 1_00, 10_000_00)
    
    # Optional fields:    
    assert_within_range( my_valid_products, 'digitalzoom', 1, 100)
    
    @logfile.close
  end
  
  desc "Check that scraped data isn't wonky"
  task :printers => [:printer_init] do
    
    @logfile = File.open("./log/check_#{$model.name}.log", 'a+')
    timed_log 'Start printer-specific validation'
    my_products = $model.instock | $model.instock_ca
    
    my_offerings = RetailerOffering.find_all_by_product_type_and_stock($model.name, true)
    
    chek_pictures(my_products)
    chek_offerings(my_offerings)
    chek_products(my_products)
    chek_linkage(my_products)
    
    announce "Testing #{my_products.count} #{$model.name}s for validity..."
    
    assert_within_range( my_products, 'itemheight', 100, 10000)
    assert_within_range( my_products, 'itemlength', 100, 7000 )
    assert_within_range( my_products, 'itemwidth', 100, 7000)
    assert_within_range( my_products, 'ppm', 2, 50)
    assert_within_range( my_products, 'paperinput', 20,2000)
    assert_within_range( my_products, 'ttp', 7,40)
    assert_within_range( my_products, 'resolutionmax', 600, 9600)
    
    
    @logfile.close
  end

  task :printer_pictures => [:printer_init, :pictures]

  task :pictures do
    require 'helpers/image_helper'
    include ImageHelper
    include ImageValidator
    
    checkme = $model.instock | $model.instock_ca
    chek_pictures checkme
  end
  
  task :printer_init => :init do
      $model = Printer
      $scrapedmodel = ScrapedPrinter
      $id_field = 'id'
      
      $product_series = $printer_series
      $reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'ppm', 'resolutionmax',\
         'paperinput','scanner', 'printserver', 'brand', 'model']
      $reqd_offering_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
         'local_id', "product_type", "region", "retailer_id"]
      $min_price = 1_00
      $max_price = 10_000_00
      
  end
  
  task :cam_init => :init do    
      $model = Camera
      $scrapedmodel = ScrapedCamera
      $id_field = 'id'
      $product_series = []
      $reqd_fields = ['itemheight', 'itemwidth', 'itemlength', 'opticalzoom', 'maximumresolution', \
        'displaysize', 'brand', 'model', 'itemweight'] 
        # 'slr', 'waterproof', 
        # , 'imagesurl', 'imagemurl', 'imagelurl'
      $reqd_offering_fields = ['priceint', 'pricestr', 'stock', 'condition', 'priceUpdate', 'toolow', \
         'local_id', "product_type", "region", "retailer_id"]
      $min_price = 1_00
      $max_price = 10_000_00
  end
  
  task :init => :environment do 
    require 'validation_libs'
    include ValidationLib
    include Check
  end    
  
end