desc "Discovering Amazon Categories"
task :amazon_test => :environment do
  require 'rubygems'
  require 'scrubyt'
 #$: << File.join(File.dirname(__FILE__), '..')
   #link = 'http://www.amazon.com/s/qid=1225325162/ref=sr_pg_2?ie=UTF8&rs=330405011&rh=n%3A502394%2Cn%3A281052%2Cn%3A330405011&page=1'
link = "http://www.amazon.com/s/qid=1226364020/ref=sr_nr_p_display_size-bin_1/182-9087234-8363816?ie=UTF8&rs=330405011&bbn=330405011&rnid=15785001&rh=n%3A502394%2Cn%3A281052%2Cn%3A330405011%2Cp_4%3ACanon%2Cp_n_feature_two_browse-bin%3A405450011%2Cp_display_size-bin%3A00"
   camera_data = Scrubyt::Extractor.define do
     fetch link 
     camera "Canon PowerShot" do
       my_url
     end#.select_indices([:first,:every_second])

 # 5 under /html/body/table/tr/td/table/tr/td/table/tr/td/table/tr/td/table/tr/td/table/tr/td/div/a/span
#   2-2.9 in      /html[1]/body[1]/table[3]/tr[1]/td[1]/table[1]/tr[2]/td[2]/table[1]/tr[1]/td[1]/table[1]/tr[11]/td[1]/table[1]/tr[1]/td[1]/table[1]/tr[1]/td[1]/div[2]/a[1]/span[1]
#                 /html[1]/body[1]/table[3]/tr[1]/td[1]/table[1]/tr[2]/td[2]/table[1]/tr[1]/td[1]/table[1]/tr[7]/td[1]/table[1]/tr[1]/td[1]/table[1]/tr[1]/td[1]/div[1]/a[1]/span[1]
   end  
   camera_data.export(__FILE__)
#my_file = File.new("myFileAmazonC.txt", "w")
#my_file.puts link  
puts camera_data.to_xml
#product_data_hash = camera_data.to_hash
#a = camera_data.to_hash
#puts a.length
#puts a[0].keys
#puts camera_data.to_xml

#a.each do |url|
#  @product = Camera.create(item)
#  @product.save
  #@camera = Camera.new
  #puts url[2].to_s #URL
   #Title
  #puts a[0][:my_category]  
  #@camera.save
#  puts url[:range_item]
#  puts url[:range_url]
#end
end

desc "Fix leaf boolean"
task :fix_leaf => :environment do
  AmazonGroup.find(:all).each {|myg|
    if !myg.brand.blank? && !myg.megapixel.blank? && !myg.zoom.blank? && !myg.displaySize.blank? && !myg.imageStabilization.blank? && !myg.viewFinderType.blank?
      myg.leaf = true
      myg.save!
    end
  }
end

desc "Correct all leafs"
task :correct_all_leaves => :environment do
  AmazonGroup.leafs.each {|myleaf|
    system "rake correct_leaf GROUP=#{myleaf.id} --trace"  
  }
end

desc "Correct leaf values"
task :correct_leaf => :environment do
  require 'rubygems'
  require 'scrubyt'
  group = ENV["GROUP"]
  if group.nil? then Process.exit end
  mygroup = AmazonGroup.find(group)
  link = "http://www.amazon.com" + mygroup.url
  camera_data = Scrubyt::Extractor.define do
     fetch link 
     #brand  ({:generalize => false}) do
      # my "5.9 MP & Under"
      # /html[1]/body[1]/table[3]/tr[1]/td[1]/table[1]/tr[2]/td[2]/table[1]/tr[1]/td[1]/table[1]/tr[5]/td[1]
       brand "/html/body/table/tr/td/table/tr/td/table/tr/td/table/tr/td/div[1]", ({:generalize => false}) 
#              /html/body/table/tr/td/table/tr/td/table/tr/td/table/tr[7]/td/table
  end  
  if ((camera_data[0].to_s != "Department" ||
     camera_data[1].to_s != "Brand" ||
     camera_data[2].to_s != "Megapixels" ||
     camera_data[3].to_s != "Optical Zoom" ||
     camera_data[4].to_s != "Display Size") &&
     (camera_data[0].to_s != "Department" ||
     camera_data[1].to_s != "Brand" ||
     camera_data[2].to_s != "Shipping Option" ||
     camera_data[3].to_s != "Megapixels" ||
     camera_data[4].to_s != "Optical Zoom" ||
     camera_data[5].to_s != "Display Size"))

     mygroup.leaf = false
     mygroup.save!
   end
#camera_data.each do |url|
#  puts url.to_s #desc
#end
end
  