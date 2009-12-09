namespace :sandbox do
  
  task :match_reviews => :environment do 
    $model = Camera
    $scrapedmodel = ScrapedCamera
    
    allrevus = Review.find_all_by_product_id_and_product_type(nil, $model.name)
    
    allrevus[0..10].each do |revu|      
      #puts "Review #{revu.id} : "
      #puts revu.summary
      #puts revu.content
      lid =  revu['local_id']
      sms = $scrapedmodel.find_all_by_local_id(lid)
      sms.each do |sm|
        #puts "#{revu.id} matches #{$model.name} #{sm.product_id}, #{$model.find(sm.product_id).title}"
        
      end
    end
    
  end
  
  task :chek_pic_sizes => :environment do
     require 'helpers/image_helper.rb'
     require 'fileutils'
     include ImageHelper
     $imgfolder = 'printers'
     $model = Printer
     
     Printer.all.each do |p|
       already = false
       ['s','m','l'].each do |sz|
         attrname = "image#{sz}url"
         hname = "image#{sz}height"
         wname = "image#{sz}width"
         url = p[attrname]
         if url.nil?
           if p[hname] or p[wname]
             puts "Warning: height or width exists for nil url"
           end
         end
       end 
     end
   end
  
  task :chek_pix => :environment do
     require 'helpers/image_helper.rb'
     require 'fileutils'
     include ImageHelper
     $imgfolder = 'printers'
     $model = Printer
     counter = 0
     pcounter = 0
     
     Printer.all.each do |p|
       already = false
       ['s','m','l'].each do |sz|
         attrname = "image#{sz}url"
         url = p[attrname]
         if url
           file = url.gsub(/images/, 'public/system')
           if !File.exists?(".#{file}")
             puts "Warning! #{file} does not exist locally. This is #{attrname} of #{$model.name} #{p.id}"
             #p.update_attribute(attrname, nil)
             counter += 1 
             pcounter += 1 and already = true if already == false
           end
         end
       end 
     end
     puts "#{counter} pix in #{pcounter} #{$model.name} don't exist locally"
   end
  
  
  task :fix_img_exts => :environment do
    require 'helpers/image_helper.rb'
    require 'fileutils'
    include ImageHelper
    $imgfolder = 'printers'
    Printer.all.each do |p|
      ['s','m','l'].each do |sz|
        attrname = "image#{sz}url"
        url = p[attrname]
        if url and url.match(/JPEG/) and !url.match(/http/)
          oldfile = url.gsub(/images/, 'public/system')
          if !File.exist?(oldfile)
            p.update_attribute(attrname, nil)
          end
        end
      end 
    end
  end
  
  task :fix_img_filenames => :environment do
    require 'helpers/image_helper.rb'
    require 'fileutils'
    include ImageHelper
    $imgfolder = 'printers'
    Printer.all.each do |p|
      ['s','m','l'].each do |sz|
        attrname = "image#{sz}url"
        url = p[attrname]
        if url and url.match(/images\//) and !url.match(/http/)
          newfile = filename_from_id(p.id,sz)
          oldfile = url.gsub(/images/, 'public/system')
          newurl = newfile.gsub(/public\/system/, 'images')
          if url and newurl and url != newurl and File.exist?(oldfile)
            FileUtils.mv(".#{oldfile}", newfile)
            p.update_attribute(attrname, newurl)
            puts "#{oldfile} --> #{newfile}"
          end
        elsif url and url.match(/http/)
          p.update_attribute(attrname, nil)
        end
      end 
    end
  end
  
  task :fix_cam_ros => :environment do
    cro = RetailerOffering.find_all_by_product_type('Camera')
    cro_no_m = cro.reject{|x| !x.merchant.nil?}
    cro_no_m.each do |ro|
      merchant = case ro.retailer_id
                 when 1 then "ATVPDKIKX0DER"
                 when 8 then "A3DWYIK6Y9EEQB"
                 else nil
                 end
      if(ro.merchant.nil?)
        ro.update_attribute('merchant', merchant)
      end
    end
  end
  
 task :move_data => :environment do
    puts 'Moving data from Cams to Scraped Cams'
    require 'helper_libs'
    include DataLib
    Camera.all.each do |cam|
      atts = cam.attributes
      atts['local_id'] = atts['asin']
      atts['product_id'] = cam.id
      create_product_from_atts(atts, ScrapedCamera)
    end
    puts 'Done'
  end
  task :move_data_2 => :environment do
    puts 'Moving data'
    require 'helper_libs'
    include DataLib
    Review.all.each do |rvu|
      fill_in('local_id',rvu.asin,rvu) if rvu.asin
    end
    puts 'Done'
  end
  
  task :move_resmax => :environment do
      puts 'Moving data from maxres to resmax in Cams'
      require 'helper_libs'
      include DataLib
      Camera.all.each do |cam|
        val = cam.maximumresolution
        cam.update_attribute('resolutionmax', val)
      end
      puts 'Done'
   end
   
   task :move_localid => :environment do
     puts 'Moving local_id from SC to RO'
     require 'helper_libs'
     include DataLib
     ScrapedCamera.all.each do |sc|
       ros = RetailerOffering.find_all_by_product_type_and_product_id('Camera',sc.product_id)
       val = sc.local_id
       ros.each do |ro|
         ro.update_attribute('local_id', val)
       end
     end
     puts "Done"
  end
end