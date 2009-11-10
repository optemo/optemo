namespace :pictures do
  
  desc 'Get all the missing pictures for Printers'
  task :update_printer_pix => [:printer_init, :dl_missing_pix, :resize_missing, :close_log]
  
  desc 'Re-download all pictures for Printers'
  task :scrape_printer_pix => [:printer_init, :dl_pix, :resize_all, :close_log]
  
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
  
  
  task :dl_pix do
    
    failed = []
    urls = {}
    $model.all.each do |product| 
      sps = $scrapedmodel.find_all_by_product_id(product.id)
      temp_url = sps.collect{|x| x.imageurl}.reject{|x| x.nil?}.first
      if temp_url
        urls[product.id] = temp_url
      else
        #TODO log
        failed << product.id
      end 
    end  
    
    failed << download_all_pix(urls)
    log " Num Failed: #{failed.size}"
  
  end
  
  task :resize_all do 
    puts "Resizing.."
    failed = resize_all urls.keys
    
    puts " Num Failed: #{failed.size}"
    withpix = $model.all.reject{|x| x.imagesurl.nil?}
    #debugger
    record_pic_stats(withpix)
    
    puts "Done"
  end
  
  task :resize_missing do
    have_urls = $scrapedmodel.all.reject{|x| x.imageurl.nil?}.collect{|x| x.product_id}.uniq
    no_resized_urls = $model.all.reject{|x| !x.imagesurl.nil? and !x.imagemurl.nil? and !x.imagelurl.nil?}
    unresized = no_resized_urls.reject{|x| !have_urls.include?(x.id)}
    
    #unresized = unresized.reject{|x| x.imagesurl.nil? or x.imagemurl.nil? or x.imagelurl.nil?}
    log "Resizing #{unresized.length} pictures"
    failed = resize_all unresized.collect{|x| x.id}
    log " Num Failed: #{failed.size}"
    
    log "Recording pic stats"
    record_pic_stats(unresized)
    
    puts "Done"
  end
  
  
  task :dl_missing_pix do
    picless = picless_recs
    really_picless = picless.reject{|x| (!x.imagesurl.nil? and !x.imagemurl.nil? and !x.imagelurl.nil?) or !x.instock}
    
    puts "Will download #{really_picless.count} pictures."
    
    failed = []
    urls = {}
    really_picless.each do |product| 
      sps = $scrapedmodel.find_all_by_product_id(product.id)
      temp_url = sps.collect{|x| x.imageurl}.reject{|x| x.nil?}.first
      if temp_url
        urls[product.id] = temp_url
      else
        #TODO log
        failed << product.id
      end 
    end
    
    log "Downloading #{urls.length} missing picture files"
    failed << download_all_pix(urls)
    log " Num Failed: #{failed.size}"

  end
end