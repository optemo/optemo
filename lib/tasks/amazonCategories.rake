desc "Discovering Amazon Categories"
task :amazon_categories => :environment do
 #Create Root node in the table
 #This should point to the page where we are collecting the categories
 root = AmazonGroup.new
 root.url = '/s/qid=1225325162/ref=sr_pg_2?ie=UTF8&rs=330405011&rh=n%3A502394%2Cn%3A281052%2Cn%3A330405011&page=1'
 root.save!
 #Launch Rake tasks seperately as Scrubyt can only be initialized once
 while AmazonGroup.unprocessed.count > 0
   system "/usr/local/bin/rake process_nodes --trace"#{}" 2>&1 >> #{Rails.root}/log/rake.log &"
 end
 puts "Discovering Categories is Complete"
end

desc "Processes all the Amazon Group Nodes"
task :process_nodes => :environment do
 #Pick a group to process
 mygroup = AmazonGroup.unprocessed.first
 unless mygroup.nil?
  puts "Processing " + mygroup.url
  mygroup.processed = true
  #Start the processing and save
  mygroup.selectNextVar if mygroup.save!
 else
     puts "All groups have been processed."
 end
end

desc "Process all Amazon Group leaf nodes"
task :process_leafs => :environment do
  AmazonGroup.leafs.each {|mynode|
    mynode.scrapedAt = Time.now
    mynode.save!
    system "rake amazon_all_details GROUP=#{mynode.id} --trace"  
   system "rake amazon_all_details --trace"  
  }
end

desc "Get All Product Details"
task :amazon_all_details => :environment do
  require 'rubygems'
  require 'scrubyt'
  ##Fetch the group for the category information
  #mygroup = AmazonGroup.find(ENV["GROUP"])


  lin = 'http://www.amazon.com/s/qid=1225325162/ref=sr_pg_2?ie=UTF8&rs=330405011&rh=n%3A502394%2Cn%3A281052%2Cn%3A330405011&page=1'
  pageMax = 1   
  camera_data = Scrubyt::Extractor.define do
    fetch lin

     camera ("/html/body/table/tr/td/div/table/tr/td/table/tr/td/table/tr/td/table", { :generalize => true }) do #("/html/body/table/tr/td/div/form/table/tr/td/table/tr/td/table/tr/td/table", { :generalize => true }) do
        title ("/tr[2]/td[1]/div[1]/a[1]/span[1]", { :write_text => true }) do#"Canon PowerShot A590IS 8MP Digital Camera with 4x Optical Image Stabilized Zoom",{:write_text => true}    #("/tr[2]/td[1]/div[1]", {:write_text => true}) do 
          camera_url do 
              url_details do 
                  cameraTechInfo("/html/body/div/div/ul", {:generalize => true }) do
                      techInfo("ul")
                  end.select_indices([:first])
                  techTitle "See more technical details", {:generalize => true} do
                      tech_url do  
                        url_details do                         
                          cameraTechInfo2("/html/body/div/div/div[3]/ul", { :generalize => true }) do
                             techInfo2("ul")
                          end
                        end         
                     end.ensure_presence_of_pattern 'techInfo2'                                             
                  end
              end
          end         
        end   
       oldPrice("/tr[3]/td[1]/div[1]/table[1]/tr[1]/td[1]/span[2]") #"$149.99"      #("/tr[3]/td[1]/div[1]/table[1]/tr[1]/td[1]/span[2]")
       newPrice("/tr[3]/td[1]/div[1]/table[1]/tr[1]/td[1]/span[3]") #"$110.30"         #("/tr[3]/td[1]/div[1]/table[1]/tr[1]/td[1]/span[3]")
       comment("/tr[3]/td[1]/div[1]/table[1]/tr[4]/td[1]")
       review("/tr[4]/td[1]/span[1]/span[1]") do
         review_url("href", { :type => :attribute })
       end
       image("/tr[1]/td[1]/table[1]/tr[1]/td[1]/a[1]/img[1]") do
         image_url("src", { :type => :attribute }) do
           image("camera_images", { :type => :download })
         end
       end  
     end   
     next_page("//a[@id=pagnNextLink]", { :limit => pageMax})
  end 

    


######Previous Code: 

  h = camera_data.to_hash
  h.each {|current|
   @camera = Camera.new(current)
#   @camera.brand = mygroup.brand
#   @camera.megapixel = mygroup.megapixel
#   @camera.zoom = mygroup.zoom
#   @camera.displaySize = mygroup.displaySize
#   @camera.imageStabilization = mygroup.imageStabilization
#   @camera.viewFinderType = mygroup.viewFinderType
#   #TODO: THis needs to be fixed as it points to results page
#   @camera.url = mygroup.url
   @camera.save!
  }
end