desc 'Download laptop data'
task :scrape_walmart => :environment do 
  require 'nokogiri'
  doc = Nokogiri::HTML(File.open("/Users/janulrich/Desktop/walmart.html")) do |config|
  end
  all_records = doc.css(".item")
  debugger
  i_records = []
  all_records.each do |item|
    imgurl = item.css(".prodImg").attribute("src").content
    title = item.css(".prodLink").first.content
    next if item.css(".ProdDesc li").empty?
    features = item.css(".ProdDesc li").map{|d| d.content}.join(" ") #Model is still in an html tag
    next if item.css(".PriceXLBold").empty?
    pricefield = item.css(".PriceXLBold").first.content
    
    #Extract data
    i = Laptop.new
    
    price = pricefield[/\d+\.\d\d/].to_f
    i.pricestr = "$#{"%.2f" % price}"
    i.price = price * 100
    #RAM
    m = features[/(\d) ?GB\s?(DDR|Memory|memory|of memory|shared)/]
    i.ram = $~[1] if m
    unless i.ram
      m = features[/(\d+) MB DDR/]
      i.ram = $~[1].to_i/1000 if m
    end
    
    #HD
    m = features[/(\d+)\s?GB\s?(hard drive|SATA|7200|5400)/i]
    i.hd = $~[1] if m
    unless i.hd
      m = features[/Hard Drive Capacity: (\d+)\s?GB/i] 
      i.hd = $~[1] if m
    end
    
    #Brand
    i.brand = title.split.first
    
    #Screen size
    m = title[/([0-9.]+)"/]
    i.screensize = $~[1] if m
    unless i.screensize
      m = features[/([0-9.]+)"/]
      i.screensize = $~[1] if m
    end
    
    i.title = title
    i.instock = true
    i.imgurl = imgurl
    i_records << i
  end
  puts "Items found: #{all_records.count}"
  Laptop.transaction do
    i_records.each(&:save)
  end
  
end