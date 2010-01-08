namespace :sandbox do
  
  
  task :fix_reviews => :environment do
    
      require 'helper_libs'

      include GenericScraper    
      include ParsingLib
      include CleaningLib
      include LoggingLib
      include DatabaseLib
      include ScrapingLib
      
      Review.all.each do |product|
        
        debugger if product.retailer_id
        fill_in('retailer_id', 1, product)
              
      end  
  end
  
  
  task :vote_on_models => :environment do
    
      require 'helper_libs'

      include GenericScraper    
      include ParsingLib
      include CleaningLib
      include LoggingLib
      include DatabaseLib
      include ScrapingLib
      
      $model.all.each do |product|
        sps = $scrapedmodel.find_all_by_product_id(product.id)
        avg_atts = {}
        debugger
        vote_on_id_fields sps, avg_atts
        debugger
        fill_in_all(avg_atts, product)
      end
  end
    
  task :test_stuff => :environment do
  
    require 'helper_libs'
    
    include GenericScraper    
    include ParsingLib
    include CleaningLib
    include LoggingLib
    include DatabaseLib
    include ScrapingLib
  
    #samples = []
    #samples << [[1,2,3], [1,2,3], [1,2,3] ]
    #samples << [[1,2,4], [1,2,3], [1,2,3] ]
    #samples << [[1,2,3], [1,2,3], [1,2,4] ]
    #samples << [[1,2,4], [1,2,3], [1,1,1] ]
    #samples << [[1,2,nil], [1,2,nil], [1,1,1] ]
    #samples << [[1,2,0], [1,2,0], [1,1,1] ]
    #
    #samples.each do |sets|
    #  best = vote_on_dimensions( sets) || []
    #  puts "[#{best*','}] selected" 
    #end
  
  end
  
  
  task :reorder_dims => :environment do
  
    require 'helper_libs'
    
    include GenericScraper    
    include ParsingLib
    include CleaningLib
    include LoggingLib
    include DatabaseLib
    
    $model = Camera
    $scrapedmodel = ScrapedCamera
    
    which_product_ids = Camera.all.collect{|x| x.id}
    
    dimlabels = ['itemlength', 'itemwidth', 'itemheight']
    
    which_product_ids.each do |pid| 
      sps = ScrapedCamera.find_all_by_product_id(pid)
      if sps.length != 0
        sps.each do |sp|
          atts = sp.attributes.reject{|a,b| !dimlabels.include?(a.to_s)}
          all_vals_to_s!(atts)
          rearrange_dims!(atts, ['D', 'H', 'W'], true)
          fill_in_all(atts,sp)
        end
      end
      p = Camera.find(pid)
      avgs = vote_on_values(p)
      fill_in_all(avgs, p)
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