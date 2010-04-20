desc 'Download laptop data'
task :scrape_walmart do 
  require 'nokogiri'
  doc = Nokogiri::HTML(File.open("/Users/janulrich/Desktop/walmart.html")) do |config|
  end
  all_records = doc.css(".item")
  all_records.each do |item|
    imgurl = item.css(".prodImg").attribute("src")
    title = item.css(".prodLink").first.content
    next if item.css(".ProdDesc li").empty?
    features = item.css(".ProdDesc li").map{|d| d.content}.join(" ") #Model is still in an html tag
    next if item.css(".PriceXLBold").empty?
    pricefield = item.css(".PriceXLBold").first.content
    
    #Extract data
    
    price = pricefield[/\$\d+\.\d\d/]
    
    #RAM
    m = features[/(\d) ?GB\s?(DDR|Memory|memory|of memory|shared)/]
    ram = $~[1] if m
    unless ram
      m = features[/(\d+) MB DDR/]
      ram = $~[1].to_i/1000 if m
    end
    
    #HD
    m = features[/(\d+)\s?GB\s?(hard drive|SATA|7200|5400)/i]
    hd = $~[1] if m
    unless hd
      m = features[/Hard Drive Capacity: (\d+)\s?GB/i] 
      hd = $~[1] if m
    end
    
    #Brand
    brand = title.split.first
    
    #Screen size
    m = title[/([0-9.]+)"/]
    size = $~[1] if m
    unless size
      m = features[/([0-9.]+)"/]
      size = $~[1] if m
    end
    
  end
  puts "Items found: #{all_records.count}"
end