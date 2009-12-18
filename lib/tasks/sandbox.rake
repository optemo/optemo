namespace :sandbox do

  task :info2 => :environment do 
    require 'helpers/parsing/idfields'
    require 'helpers/parsing/strings'
    require 'helpers/global_constants'
    require 'helpers/database/fill_in'
    include Constants
    include PrinterConstants
    include IdFieldsHelper
    include StringCleaner
    include FillInHelper
    $model = @@model
    $brands = @@brands
    $series = @@series

    result = @@model.all.inject([]){|r,x|
      r << x if likely_model_name(x.model) < 1 or likely_model_name(x.mpn) < 1 
      r
    }  
    
    debugger
    
    puts result
    
  end
    
  task :info => :environment do 
    require 'helpers/parsing/idfields'
    require 'helpers/parsing/strings'
    require 'helpers/global_constants'
    require 'helpers/database/fill_in'
    include Constants
    include PrinterConstants
    include IdFieldsHelper
    include StringCleaner
    include FillInHelper
  
    stuff = []
    @@model.all.each do |x|
      stuff << x.model
      stuff << x.mpn
    end
    buckets = 10
    count = no_blanks(stuff).inject({}){|r,x|
      
      consec_nums = x.scan(/\d+/).collect{|x| (x || '').to_s.length}.sort.last || 0
      #debugger if consec_nums > 6
      #nums_only = x.gsub(/\D/,'')
      total = just_alphanumeric(x).length
      #num_digits = nums_only.length
      #percent = num_digits.to_f/total
      #bucket = ((percent*100.0)/buckets).to_i
      
      #bucket = case num_digits when 3..8 then 1 else 0 end
      
      #r[bucket] = 1 + (r[bucket] || 0)
      
      r[consec_nums] = 1 + (r[consec_nums] || 0)
      
      r
    }
    
    count.keys.sort.each do |k|
      puts "#{count[k]} have #{k} max consecutive"#{}"##{k*buckets}% -- #{(k+1)*buckets-1}% numeric chars"
    end
    
  end
  
  task :fix_brands => :environment do 
    require 'helpers/parsing/idfields'
    require 'helpers/parsing/strings'
    require 'helpers/global_constants'
    require 'helpers/database/fill_in'
    include Constants
    include CameraConstants
    include IdFieldsHelper
    include StringCleaner
    include FillInHelper
    
    @@scrapedmodel.all.each do |ptr|   
        temp = clean_brand("#{ptr.title} #{ptr.brand}", @@brands) || ''
        temp2 = "#{ptr.brand}" || ''
        
        if temp != temp2 and temp != ''
          #debugger 
          fill_in 'brand', temp, ptr
        end
    end
  end
  
  task :fix_models => :environment do 
    require 'helpers/parsing/idfields'
    require 'helpers/parsing/strings'
    require 'helpers/global_constants'
    require 'helpers/database/fill_in'
    include Constants
    include PrinterConstants
    include IdFieldsHelper
    include StringCleaner
    include FillInHelper
    
    newbrands = []
    
    $model= @@model
    $series = @@series
    $brands = @@brands
    
    fixme =  @@scrapedmodel.all.reject{|x| (x.model and x.mpn and likely_model_name(x.model) > 1 and likely_model_name(x.mpn) > 1 )}
    debugger
    fixme.each do |ptr|   
        #newbrands << clean_brand("#{ptr.title} #{ptr.model}", @@brands) || ''
        modelsb4 = no_blanks([ptr.model, ptr.mpn]).uniq
        modelsafter = no_blanks(
                  clean_models(
                    @@model.name, ptr.brand, modelsb4, ptr.title,@@brands, @@series, @@descriptors
                  )
                ).uniq.reject{|x| 
          (x.nil? or x == '' or likely_model_name(x) < 2)
          }.sort{|a,b| 
            likely_model_name(b) <=> likely_model_name(a)}
        
       models = modelsafter[0..1]
       fill_in 'model', models[0], ptr
       fill_in 'mpn', models[1], ptr
    end
  end
  
  task :test_model_cleaner => :environment do
    
   require 'helper_libs' 
   
    @@scrapedmodel.all[0..15].each do |sp|
      puts "#{sp.title}"
      x = model_cleaner(sp.attributes, @@brands)
      puts "#{x * ','}"
      puts " ------- "
    end
    
  end
  
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
      create_record_from_atts (atts, ScrapedCamera)
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