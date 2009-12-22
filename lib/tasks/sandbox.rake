namespace :sandbox do
  
  task :blah => :environment do 
    
    Camera.all.each do |c|
      scs = ScrapedCamera.find_all_by_camera_id
    end
  end
  
  task :validate => :environment do 
    require 'helpers/parsing/idfields'
    require 'helpers/parsing/strings'
    require 'helpers/global_constants'
    include Constants
    include PrinterConstants
    include IdFieldsHelper
    include StringCleaner
    
    $model = @@model
    $series = @@series
    $brands = @@brands
    
    
    id_able = @@scrapedmodel.all.reject{|x|  (x.model.nil? or x.mpn.nil?) 
      }.reject{|y| likely_model_name(y.model) < 2 or likely_model_name(y.mpn) < 2 }
    
    puts "#{@@model.count} total, with #{@@scrapedmodel.count} scraped"
    puts "#{id_able.count} of #{@@scrapedmodel.count} identifiable"
    
  end
  
  task :fix_models => :environment do 
    require 'helpers/parsing/idfields'
    require 'helpers/parsing/strings'
    require 'helpers/global_constants'
    require 'helpers/database/fill_in'
    include Constants
    include CameraConstants
    include IdFieldsHelper
    include StringCleaner
    include FillInHelper
    
    newbrands = []
    
    $model= @@model
    $series = @@series
    $brands = @@brands
    
    fixme = @@scrapedmodel.all
    
    #fixme.delete_if{|x|  !x.model.nil? and !x.mpn.nil? and \
    #  (likely_model_name(x.model) >= 2 ) and (likely_model_name(x.mpn) >= 2) 
    #}
    #
    #fixme.delete_if{|x| (x.mpn.nil? and likely_model_name(x.model) >= 3 ) or \
    #  (x.model.nil? and likely_model_name(x.mpn) >= 3 )
    #}
    counter=0
    #numToSkip=21
    #debugger
      
    fixme.each do |ptr|   
        x = ptr
        next if !x.model.nil? and !x.mpn.nil? and\
         (likely_model_name(x.model) >= 2 ) and (likely_model_name(x.mpn) >= 2) 
        next if (x.mpn.nil? and likely_model_name(x.model) >= 3 ) 
        next if (x.model.nil? and likely_model_name(x.mpn) >= 3 )
      
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
       #puts "TITLE: #{ptr.title}"
       #puts "BEFORE: #{modelsb4 * ', '}"
       #puts "AFTER: #{modelsafter * ', '} ... RATINGS: #{modelsafter.collect{|x| likely_model_name(x)} * ', '}"
       #debugger if counter > (numToSkip-1)
       unless modelsafter.length == 0
         fill_in_forced 'model', modelsafter[0], ptr
         fill_in_forced 'mpn', modelsafter[1], ptr
       end
       counter += 1
       puts "#{counter} successful"
    end
  end
  
end