namespace :pictures do
  
  desc 'Fixes broken links and gets latest picture sizes for all printer pix'
  task :update_cam_stats => [:camera_init, :update_pic_stats]
  
  desc 'Get all the missing pictures for Cameras'
  task :update_cameras => [:camera_init, :dl_missing_pix, :resize_missing, :update_pic_stats, :close_log]
  
  desc 'Re-download all pictures for Cameras'
  task :scrape_cameras => [:camera_init, :dl_pix, :resize_all, :close_log]
  
  desc 'Get all the missing pictures for Printers'
  task :update_printers => [:printer_init, :dl_missing_pix, :resize_missing, :update_pic_stats, :close_log]
  
  desc 'Re-download all pictures for Printers'
  task :scrape_printers => [:printer_init, :dl_pix, :resize_all, :close_log]
  
  task :temp => :printer_init do
    puts "Recording pic stats"
    record_pic_stats($model.all)
    puts "Done!"
  end
  
  
  task :camera_init => :environment do 
    $model = Camera
    $scrapedmodel = ScrapedCamera
    $id_field = 'id'
    $imgfolder = 'cameras'
    
    $logfile = File.open("./log/#{$model}_pics.log", 'w+')
    
    require 'helper_libs'
    require 'RMagick'
    include ImageLib
  end
  
  task :printer_init => :environment do 
    $model = Printer
    $scrapedmodel = ScrapedPrinter
    $id_field = 'id'
    $imgfolder = 'printers'
    
    $logfile = File.open("./log/#{$model}_pics.log", 'w+')
    
    require 'helper_libs'
    require 'RMagick'
    include ImageLib
    
  end
  
  task :close_log do
    $logfile.close
  end
  
  task :update_pic_stats do
    updateme = $model.all
    record_pic_stats(updateme)
  end
  
  task :dl_pix do
    puts "Downloading all pictures"
    failed = []
    urls = {}
    $model.all.each do |product| 
      sps = $scrapedmodel.find_all_by_product_id(product.id)
      temp_url = sps.collect{|x| x.imageurl}.reject{|x| x.nil?}.first
      if temp_url
        urls[product.id] = temp_url
      else
        failed << product.id
      end 
    end  
    
    failed << download_all_pix(urls)
    log " Num Failed: #{failed.size}"
  
  end
  
  task :resize_missing do
    have_urls = $scrapedmodel.all.reject{|x| x.imageurl.nil?}.collect{|x| x.product_id}.uniq
    no_resized_urls = $model.all.reject{|x| !x.imagesurl.nil? and !x.imagemurl.nil? and !x.imagelurl.nil?}
    unresized = no_resized_urls.collect{|x| x.id}.reject{|y| !have_urls.include?(y)}
    
    log "Resizing #{unresized.length} pictures"
    failed = resize_all(unresized)
    log " Num Failed: #{failed.size}"
    
    log "Recording pic stats"
    record_pic_stats(unresized)
    
    puts "Done"
  end
  
  
  task :dl_missing_pix do
    puts "Downloading missing pictures"
    picless = picless_recs($model)
    puts "#{picless.count} #{$model.name} pictures are missing!"
    #really_picless = picless.reject{|x| (!x.imagesurl.nil? and !x.imagemurl.nil? and !x.imagelurl.nil?) or (!x.instock and !x.instock_ca)}
    really_picless = picless
    puts "Will download #{really_picless.count} pictures."
    
    failed = []
    urls = {}
    really_picless.each do |product| 
      sps = $scrapedmodel.find_all_by_product_id(product)
      temp_url = sps.collect{|x| x.imageurl}.reject{|x| x.nil?}.first
      if temp_url
        urls[product] = temp_url
      else
        failed << product
      end 
    end
    
    log "Downloading #{urls.length} missing picture files"
    failed << download_all_pix(urls)
    log " Num Failed: #{failed.size}"
  end
end