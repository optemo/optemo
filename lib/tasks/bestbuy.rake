desc "Download RSS feed"
task :bb_rss => :environment do
  require 'simple-rss'
  require 'open-uri'
  require 'Nokogiri'
  #source = "http://www.bestbuy.ca/RSSFEeds/GetProductsFeedForMobile.aspx?langid=EN" # url or local file
  source = "./tmp/bbdata.rss"
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
  h = {} #Products Hash
  atts = []
  rss.items.each do |item|
    doc = Nokogiri::XML(item.FS_ItemSpecs)
    if doc.css('ATT').count > 10
      #puts item.title + ' - ' + item.guid
      h[item.guid] = {}
      doc.css('ATT').each do |a_tag|
        h[item.guid][a_tag.css('ATT_NAME')[0].content] = a_tag.css('ATT_VALUE')[0].content
        
        atts << a_tag.css('ATT_NAME')[0].content.gsub(/\(.*\)|\/.*/,'').tr(' .()','')
      end
    end
  end
  puts atts.uniq.sort
  puts h.length
  puts atts.uniq.count
  
  #puts rss.items[2].FS_ItemSpecs
  #print "title of first item: ", rss.items[0].title, "\n"
  #print "link of first item: ", rss.items[0].link, "\n"
  #print "description of first item: ", rss.items[0].description, "\n"
  #print "date of first item: ", rss.items[0].date, "\n"
end

#<IA SKU_ID="0926INGFS10113411" FS_SKU_ID="10113411" MFG_PART_NUM="G384 TRAIL BAG">
#	<ATT DEF_AVAIL="False" ATT_ID="WEBCODE">
#		<ATT_NAME><![CDATA[Web Code]]></ATT_NAME>
#		<ATT_VALUE><![CDATA[10113411]]></ATT_VALUE>
#	</ATT>
#	<ATT DEF_AVAIL="False" ATT_ID="MFRPARTNUM">
#		<ATT_NAME><![CDATA[Mfr. Part Number]]></ATT_NAME>
#		<ATT_VALUE><![CDATA[G384 TRAIL BAG]]></ATT_VALUE>
#	</ATT>
#</IA>