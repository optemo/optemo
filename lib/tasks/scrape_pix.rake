namespace :pictures do
  
  desc 'Fixes broken links and gets latest picture sizes for all printer pix'
  task :update_cam_stats => [:camera_init, :update_pic_stats]
  
  desc 'Get all the missing pictures for Cameras'
  task :update_cameras => [:camera_init, :download_missing_pictures, :resize_missing, :update_pic_stats, :close_log]
  
  desc 'Re-download all pictures for Cameras'
  task :scrape_cameras => [:camera_init, :download_pictures, :resize_all, :close_log] # This fails, because resize_all isn't a function
  
  desc 'Get all the missing pictures for Printers'
  task :update_printers => [:printer_init, :download_missing_pictures, :resize_missing, :update_pic_stats, :close_log]
  task :update_lph_printers => [:printer_lph_init, :download_missing_pictures, :resize_missing, :update_pic_stats, :close_log]
  
  desc 'Re-download all pictures for Printers'
  task :scrape_printers => [:printer_init, :download_pictures, :resize_all, :close_log]
  
  task :temp => :printer_init do
    puts "Recording pic stats"
    record_pic_stats(Product.all(:conditions => ["product_type=?",Session.current.product_type]))
    puts "Done!"
  end
  
  task :camera_init => :environment do 

    Session.new("cameras")
    $scrapedmodel = ScrapedCamera
    
    $logfile = File.open("./log/#{Session.current.product_type}_pics.log", 'w+')
    
    require 'helper_libs'
    require 'RMagick'
    include ImageLib
  end
  
  task :printer_init => :environment do 
    Session.new("printers")
    $scrapedmodel = ScrapedPrinter
    
    $logfile = File.open("./log/#{Session.current.product_type}_pics.log", 'w+')
    
    require 'helper_libs'
    require 'RMagick'
    include ImageLib
    
  end

  task :printer_lph_init => :environment do 
    Session.new("laserprinterhub.com")
    $scrapedmodel = ScrapedPrinter
    
    $logfile = File.open("./log/#{Session.current.product_type}_pics.log", 'w+')
    
    require 'helper_libs'
    require 'RMagick'
    include ImageLib
    
  end
  
  task :close_log do
    $logfile.close
  end
  
  task :update_pic_stats do
    record_pic_stats(Product.find(:all, :conditions => ["product_type=?", Session.current.product_type]))
  end
  
  task :download_pictures do
    puts "Downloading all pictures"
    failed = []
    urls = {}
    Product.all(:conditions => ["product_type=?", Session.current.product_type]).each do |product|
      sps = $scrapedmodel.find(:all, :conditions => ["product_id=?",product.id])
      temp_url = sps.collect{|x| x.imageurl}.reject{|x| x.blank?}
      if temp_url
        urls[product.id] = temp_url
      else
        failed << product.id
      end 
    end  
    
    failed << download_all_pictures(urls)
    log " Num Failed: #{failed.size}"
  
  end
  
  task :resize_missing do
    have_urls = $scrapedmodel.all.reject{|x| x.imageurl.nil?}.collect{|x| x.product_id}.uniq
    products = Product.find(:all, :conditions => ["product_type=?", Session.current.product_type])
    no_resized_urls = products.reject{|x| !x.imgsurl.nil? and !x.imgmurl.nil? and !x.imglurl.nil?}
    unresized = no_resized_urls.reject{|y| !have_urls.include?(y)}
    unresized += no_resized_urls.reject{|product| not (filename_from_id(product.id,""))}
    
    products_with_unresized_images = products.select{|product| File.exist?(filename_from_id(product.id,""))}
    products_without_resized_images = products.reject{|product| ["s","m","l"].inject(true){|result,sz| result & File.exist?(filename_from_id(product.id,sz))}}
    # Take the intersection of those products with unresized images, like 1094.jpg, but without resized images, like 1094_l.jpg
    unresized += (products_with_unresized_images & products_without_resized_images)
    unresized_ids = unresized.map{|x|x.id}
    log "Resizing #{unresized_ids.length} pictures"
    failed = resize_all(unresized_ids)
    log " Num Failed: #{failed.size}"
    
    log "Recording pic stats"
    # We need to pass a list of products, not just a list of product_ids
    unless unresized_ids.empty?
      pid_string = "id IN (" + unresized_ids.inject(""){|pid_string,pid|pid_string + pid.to_s + ","}.chop + ")"
      # The line below is not needed anymore for the main rake tasks, BUT, if you run resize_missing on its own you will miss the pic stats part.
      #record_pic_stats(Product.find(:all, :conditions => [pid_string]))
    end
    puts "Done"
  end
  
  
  task :download_missing_pictures do
    puts "Downloading missing pictures"
    picless = picless_records()
    puts "#{picless.count} #{Session.current.product_type} pictures are missing!"
    #really_picless = picless.reject{|x| (!x.imagesurl.nil? and !x.imagemurl.nil? and !x.imagelurl.nil?) or (!x.instock and !x.instock_ca)}
    really_picless = picless
    puts "Will download #{really_picless.count} pictures."
    
    failed = []
    urls = {}
    really_picless.each do |current_product| 
      sps = $scrapedmodel.find(:all, :conditions => ["product_id=?",current_product.id])
      
      #if sps.empty? # Try another method of finding the image URL: the model name (either alone or in the title)
      sps += $scrapedmodel.find_all_by_model(current_product.model) + $scrapedmodel.find(:all, :conditions => ["title regexp ?", current_product.model]) unless current_product.model.nil?
      sps += $scrapedmodel.find_all_by_mpn(current_product.mpn) + $scrapedmodel.find(:all, :conditions => ["title regexp ?", current_product.mpn]) unless current_product.mpn.nil?
      #end
      temp_urls = sps.collect{|x| x.imageurl}.reject(&:blank?)
      unless temp_urls.nil? || temp_urls.empty?
        urls[current_product.id] = temp_urls
      else
        failed << current_product.id
      end 
    end
    
    log "Downloading #{urls.length} missing picture files"
    failed << download_all_pictures(urls)
    log " Num Failed: #{failed.size}"
  end
  
  task :disable_products_with_missing_pictures do
    puts "Product.valid.instock has length: " + Product.valid.instock.length
    picless = picless_records()
    puts "#{picless.count} #{Session.current.product_type} pictures are missing!"
    picless.each{|pid| (Product.find(pid).instock = false).save }
    puts "Now Product.valid.instock has length: " + Product.valid.instock.length
  end
end