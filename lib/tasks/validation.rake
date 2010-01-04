module Check
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
  
  task :cameras => [:cam_init] do #, :pictures] do
    include ValidationLib
    require 'helpers/image_helper'
    include ImageHelper
    include ImageValidator
    
    @logfile = File.open("./log/check_#{$model.name}_2.log", 'a+')
    timed_log 'Start camera-specific validation'
    my_products = $model.instock | $model.instock_ca
    my_offerings = RetailerOffering.find_all_by_product_type_and_stock($model.name, true)
    #chek_pictures(my_products)
    chek_offerings(my_offerings)
    chek_products(my_products)
    
    announce "Testing #{my_products.count} #{$model.name}s for validity..."
    
    assert_within_range( my_products, 'itemheight', 200, 450)
    assert_within_range( my_products, 'itemlength', 60, 350) # depth
    assert_within_range( my_products, 'itemwidth', 350, 600)
    
    assert_within_range( my_products, 'maximumresolution', 0.5, 50)    
    assert_within_range( my_products, 'opticalzoom', 1, 26)
    assert_within_range( my_products, 'displaysize', 1.5, 4)
    
    assert_within_range( my_products, 'price', 1_00, 10_000_00)
    
    # Optional fields:    
    assert_within_range( my_products, 'digitalzoom', 1, 100)
    
    @logfile.close
  end
  
  task :products do    
    @logfile = File.open("./log/check_#{$model.name}.log", 'w+')
    timed_log 'Start general product validation'
    #my_products = $model.instock | $model.instock_ca
    my_products = $model.all
    
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
    @logfile.close
  end
  
  task :offerings do    
    my_offerings = RetailerOffering.find_all_by_product_type_and_stock($model.name, true)
    @logfile = File.open("./log/check_#{$model.name}_offerings.log", 'w+')
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
    @logfile.close
  end
  
  desc "Check that scraped data isn't wonky"
  task :printers => [:printer_init, :products, :offerings] do
    
    @logfile = File.open("./log/check_#{$model.name}.log", 'a+')
    timed_log 'Start printer-specific validation'
    my_products = $model.instock | $model.instock_ca
    
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