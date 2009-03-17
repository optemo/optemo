require 'rubygems'
require 'scrubyt'

desc "Scraping Amazon"
task :scrape_amazon => :environment do
  Printer.fewfeatures.find(:all, :order => 'rand()', :conditions => 'scrapedat IS NULL AND nodetails IS NOT TRUE').each { |p|
    scrape_details(p)
    sleep(1+rand()) #Be nice to Amazon
    sleep(rand()*50) #Be really nice to Amazon!
  }  
end

def scrape_details(p)
  puts 'ASIN='+p.asin
  extractor = Scrubyt::Extractor.define do
    fetch('http://www.amazon.com/o/asin/' + p.asin, :user_agent => "User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1")
    #fetch 'http://www.amazon.com/o/asin/' + 'B000F005U0'
    #fetch 'http://www.amazon.com/Magicolor-2550-Dn-Color-Laser/dp/tech-data/B000I7VK22/ref=de_a_smtd'
    begin
      click_link('See more technical details')
    rescue
      p.nodetails = true
      p.save
      return
    end
    features("Brand Name: #{p.brand}", { :generalize => true }) #, :write_text => true 
    #features("Brand Name: Xerox", { :generalize => true }) #, :write_text => true 
  end
  product_data_hash = extractor.to_hash
  array = product_data_hash.map{|i| i[:features] if i[:features].index(':')}.compact
  features = {}
  array.each {|i|
    t = i.split(': ')
    features[t[0]]=t[1]
    }
  
  #pp features
  res = []
  features.each {|key, value| 
    if key[/(M|m)aximum( |_)?(P|p)rint( |_)?(S|s)peed/]
      p.ppm = value.to_f unless !p.ppm.nil? && p.ppm >= value.to_i #Keep fastest value
      #puts 'PPM: '+p.ppm.to_s
    end
    if key[/(M|m)aximum( |_)?(P|p)rint( |_)?(S|s)peed/] && key[/(C|c)olou?r/] #Color
      p.ppmcolor = value.to_f
      #puts 'PPM(Color): '+p.ppmcolor.to_s
    end
    if key[/(F|f)irst( |_)?(P|p)age( |_)?(O|o)utput( |_)?(T|t)ime/]
      p.ttp = value.match(/\d+(.\d+)?/)[0].to_f
      #puts 'TTP:'+p.ttp.to_s
    end
    if key[/(M|m)aximum( |_)?(S|s)heet( |_)?(C|c)apacity/]
      p.paperinput = value.to_i unless !p.paperinput.nil? && p.paperinput > value.to_i #Keep largest value
      #puts 'Paper Input:'+p.paperinput.to_s
    end
    if key[/(R|r)esolution/] && res.size < 2
      res << value.match(/\d+/)[0]
    end
    if key[/(P|p)rinter( |_)?(I|i)nterface/] || (key[/Connectivity Technology/] && value != 'Wired')
      p.connectivity = value
      #puts p.connectivity
    end
    if key[/(H|h)ardware( |_)?(P|p)latform/]
      p.platform = value
      #puts 'HW: '+p.platform
    end
    if key[/Width/]
      #puts 'Width: ' + p.itemwidth.to_s + ' <> ' + value rescue nil
      p.itemwidth = value.to_f * 100
      #puts 'Width: ' + p.itemwidth.to_s
    end
    if key[/RAM/]
      p.systemmemorysize = value.match(/\d+/)[0]
      #puts "RAM" + p.systemmemorysize.to_s
    end
    if key[/(P|p)rinter( |_)?(O|o)utput/]
      p.colorprinter = !value[/(C|c)olou?r/].nil?
      #puts 'Color:' + (p.colorprinter ? 'True' : 'False')
    end
    if key[/(S|s)canner( |_)?(T|t)ype/]
      p.scanner = value[/(N|n)one/].nil?
      #puts 'Scanner:' + (p.scanner ? 'True' : 'False')
    end
    if key[/(N|n)etworking(_| )?(F|f)eature/]
      p.printserver = !value[/(S|s)erver/].nil?
    end
  }
  if p.resolution.nil?
    p.resolution = res.sort{|a,b| 
      a.gsub!(',','')
      b.gsub!(',','')
      a.to_i < b.to_i ? 1 : a.to_i > b.to_i ? -1 : 0
    }.join(' x ')
    #puts "Res: "+p.resolution
  end
  p.scrapedat = Time.now
  p.save
end

require 'open-uri'
#require 'net/http'
desc "Download Images"
task :download_images => :environment do
  Camera.find(:all).each {|c|
    c.imagesurl = download(c.imagesurl)
    c.imagemurl = download(c.imagemurl)
    c.imagelurl = download(c.imagelurl)
    c.save
  }
end

desc "Rename %2B (+)"
task :image_unescape => :environment do
  Camera.find(:all).each {|c|
    s = c.imagesurl.gsub(/%2(b|B)/,'-') if !c.imagesurl.nil?
    m = c.imagemurl.gsub(/%2(b|B)/,'-') if !c.imagemurl.nil?
    l = c.imagelurl.gsub(/%2(b|B)/,'-') if !c.imagelurl.nil?
    c.update_attributes(:imagelurl => l, :imagemurl => m, :imagesurl => s)
  }
end

def download(url)
  return nil if url.nil?
  return url if url.index(/\/images\/Amazon\//)
  url = 'http://ecx.images-amazon.com/images/I/'+url if url.length < 30 
  filename = url.split('/').pop
  puts filename
  ret = '/images/Amazon/'+filename
  begin
  f = open('/optemo/site/public/images/Amazon/'+filename,"w").write(open(url).read)
  rescue OpenURI::HTTPError
    ret = ""
  end
  ret
end
 