namespace :sandbox do
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