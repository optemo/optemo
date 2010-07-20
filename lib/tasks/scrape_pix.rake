namespace :pictures do
  
  desc 'Fixes broken links and gets latest picture sizes for all printer pix'
  task :update_cam_stats => [:camera_init, :update_pic_stats]
  
  desc 'Get all the missing pictures for Cameras'
  task :update_cameras => [:camera_init, :download_missing_pictures, :resize_missing, :update_pic_stats, :close_log]
  
  desc 'Re-download all pictures for Cameras'
  task :scrape_cameras => [:camera_init, :download_pictures, :resize_all, :close_log] # This fails, because resize_all isn't a function
  
  desc 'Get all the missing pictures for Printers'
  task :update_printers => [:printer_init, :download_missing_pictures, :resize_missing, :update_pic_stats, :close_log]
  
  desc 'Re-download all pictures for Printers'
  task :scrape_printers => [:printer_init, :download_pictures, :resize_all, :close_log]
  
  task :temp => :printer_init do
    puts "Recording pic stats"
    record_pic_stats(Product.all(:conditions => ["product_type=?",$product_type]))
    puts "Done!"
  end
  
  task :camera_init => :environment do 

    load_defaults("cameras")
    $scrapedmodel = ScrapedCamera
    
    $logfile = File.open("./log/#{$product_type}_pics.log", 'w+')
    
    require 'helper_libs'
    require 'RMagick'
    include ImageLib
  end
  
  task :printer_init => :environment do 
    load_defaults("printers")
    $scrapedmodel = ScrapedPrinter
    
    $logfile = File.open("./log/#{$product_type}_pics.log", 'w+')
    
    require 'helper_libs'
    require 'RMagick'
    include ImageLib
    
  end
  
  task :close_log do
    $logfile.close
  end
  
  task :update_pic_stats do
    record_pic_stats(Product.all(:conditions => ["product_type=?", $product_type]))
  end
  
  task :download_pictures do
    puts "Downloading all pictures"
    failed = []
    urls = {}
    Product.all(:conditions => ["product_type=?", $product_type]).each do |product|
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
    no_resized_urls = Product.all(:conditions => ["product_type=?", $product_type]).reject{|x| !x.imgsurl.nil? and !x.imgmurl.nil? and !x.imglurl.nil?}
    unresized = no_resized_urls.reject{|y| !have_urls.include?(y)}
    unresized += no_resized_urls.reject{|product| not (filename_from_id(product.id,""))}
    unresized_ids = unresized.map{|x|x.id}
    log "Resizing #{unresized_ids.length} pictures"
    failed = resize_all(unresized_ids)
    log " Num Failed: #{failed.size}"
    
    log "Recording pic stats"
    # We need to pass a list of products, not just a list of product_ids
    unless unresized_ids.empty?
      pid_string = "id IN (" + unresized_ids.inject(""){|pid_string,pid|pid_string + pid.to_s + ","}.chop + ")"
      record_pic_stats(Product.find(:all, :conditions => [pid_string]))
    end
    puts "Done"
  end
  
  
  task :download_missing_pictures do
    puts "Downloading missing pictures"
    picless = picless_records
    puts "#{picless.count} #{$product_type} pictures are missing!"
    #really_picless = picless.reject{|x| (!x.imagesurl.nil? and !x.imagemurl.nil? and !x.imagelurl.nil?) or (!x.instock and !x.instock_ca)}
    really_picless = picless
    puts "Will download #{really_picless.count} pictures."
    
    failed = []
    urls = {}
    really_picless.each do |product_id| 
      sps = $scrapedmodel.find(:all, :conditions => ["product_id=?",product_id])
      if sps.empty? # Try another method of finding the image URL: the model name
        sps = $scrapedmodel.find_all_by_model(Product.find(product_id).model)
      end
      temp_urls = sps.collect{|x| x.imageurl}.reject{|x| x.blank?}
      unless temp_urls.nil? || temp_urls.empty?
        urls[product_id] = temp_urls
      else
        failed << product_id
      end 
    end
    
    log "Downloading #{urls.length} missing picture files"
    failed << download_all_pictures(urls)
    log " Num Failed: #{failed.size}"
  end
end