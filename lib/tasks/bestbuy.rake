desc "Download RSS feed"
task :bb_rss => :environment do
  require 'simple-rss'
  require 'open-uri'
  require 'Nokogiri'
  source = "http://www.bestbuy.ca/RSSFEeds/GetProductsFeedForMobile.aspx?langid=EN" # url or local file
  #source = "./tmp/bbdata.rss"
  SimpleRSS.item_tags = SimpleRSS.item_tags + %w(FS:CategoryID FS:Manufacturer FS:ProvinceCode FS:ImageUrl FS:LongDescription FS:ItemSpecs FS:CatGroup FS:CatDept FS:CatClass FS:CatSubClass FS:Price)
  
  rss = SimpleRSS.parse open(source)
  
  puts "Root values"
  print "RSS title: ", rss.channel.title, "\n"
  print "RSS link: ", rss.channel.link, "\n"
  print "RSS description: ", rss.channel.description, "\n"
  #print "RSS publication date: ", rss.channel.date, "\n"

  puts "Item values"
  print "number of items: ", rss.items.size, "\n"
  #puts SimpleRSS.item_tags
  #rss.items.each do |i|
  #  puts i.FS_ItemSpecs if i.FS_ItemSpecs
  #end
  #puts rss.items[0].FS_CategoryID
  #puts item.FS_ItemSpecs
  atts = []
  rss.items.each do |item|
    doc = Nokogiri::XML(item.FS_ItemSpecs)
    if doc.css('ATT').count > 10
      #puts item.title + ' - ' + item.guid
      h = {}
      h['guid'] = item.guid
      h['title'] = item.title
      h['description'] = item.description
      h['link'] = item.link
      h['category'] = item.category
      h['CategoryID'] =      item.FS_CategoryID
      h['Manufacturer'] =    item.FS_Manufacturer
      h['ProvinceCode'] =    item.FS_ProvinceCode
      h['ImageUrl'] =        item.FS_ImageUrl
      h['LongDescription'] = item.FS_LongDescription
      h['CatGroup'] =        item.FS_CatGroup
      h['CatDept'] =         item.FS_CatDept
      h['CatClass'] =        item.FS_CatClass
      h['CatSubClass'] =     item.FS_CatSubClass
      h['Price'] =           item.FS_Price
      
      doc.css('ATT').each do |a_tag|
        key = a_tag.css('ATT_NAME')[0].content.gsub(/\(.*\)|\/.*/,'').tr(' .()','')
        #Special Cases
        key = 'OrderConditions' if key == 'OrderConditons'
        key = 'CustomizableRingTones' if key == 'CustomizableRingtones'
        h[key] = a_tag.css('ATT_VALUE')[0].content
      end
      b = BestBuyPhone.new(h)
      b.save if b
    end
  end
  
  #puts rss.items[2].FS_ItemSpecs
  #print "title of first item: ", rss.items[0].title, "\n"
  #print "link of first item: ", rss.items[0].link, "\n"
  #print "description of first item: ", rss.items[0].description, "\n"
  #print "date of first item: ", rss.items[0].date, "\n"
end

task :clean => :environment do
  
end
