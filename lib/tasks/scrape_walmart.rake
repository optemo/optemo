desc 'Download laptop data'
task :scrape_walmart => :environment do 
  require 'nokogiri'
  doc = Nokogiri::HTML(File.open("/Users/maryam/walmart1.html")) do |config|
  end
  all_records = doc.css(".item")
  puts all_records.size
 # debugger
  c_records = []
  t_records = []
  b_records = []
  i_records = []
  all_records.each do |item|
    imgurl = item.css(".prodImg").attribute("src").content
    title = item.css(".prodLink").first.content
    next if item.css(".ProdDesc li").empty?
    features = item.css(".ProdDesc li").map{|d| d.content}.join(" ") #Model is still in an html tag
    next if item.css(".PriceXLBold").empty?
    pricefield = item.css(".PriceXLBold").first.content
    
    #Extract data
    i = Product.new
    i.title = title
    i.instock = true
    i.imgsurl = imgurl
    i.imgmurl = imgurl
    i.product_type = "laptop_walmart"
    i.url = 
    #i_records << i
    i.save 
    
    #PRICE
    c = ContSpec.new
    price = pricefield[/\d+\.\d\d/].to_f
    #c.pricestr = "$#{"%.2f" % price}"
    c.name = "price" 
    c.value = price 
    #setRest c 
    c.product_id = i.id
    c.product_type = "laptop_walmart"
    c_records << c 
    
    #RAM
    c= ContSpec.new 
    m = features[/(\d) ?GB\s?(DDR|Memory|memory|of memory|shared)/]
    c.name = "ram" if m
    c.value = $~[1] if m
    unless c.value
      m = features[/(\d+) MB DDR/]
      c.value = $~[1].to_i/1000 if m
    end
    c.product_id = i.id 
    c.product_type = "laptop_walmart"
    c_records << c if m 
    
    #HD
    c = ContSpec.new
    m = features[/(\d+)\s?GB\s?(hard drive|SATA|7200|5400)/i]
    c.name = "hd" if m
    c.value = $~[1] if m
    unless c.value
      m = features[/Hard Drive Capacity: (\d+)\s?GB/i] 
      c.value = $~[1] if m
    end
    c.product_id = i.id 
    c.product_type = "laptop_walmart"
    c_records << c if m
    
    #Screen size
    c = ContSpec.new
    m = title[/([0-9.]+)"/]
    c.name = "screensize" 
    c.value = $~[1] if m
    unless c.value
      m = features[/([0-9.]+)"/]
    end
    c.product_id = i.id
    c.product_type = "laptop_walmart"
    c_records << c if m
    
    #Brand
    t = CatSpec.new 
    t.name = "brand" 
    t.value = title.split.first
    t.product_id = i.id
    t.product_type = "laptop_walmart"
    t_records << t
    
  end

  puts "Items found: #{all_records.count}"
  ContSpec.transaction do
    c_records.each(&:save)
  end
  
  CatSpec.transaction do
     t_records.each(&:save)
   end
   

end