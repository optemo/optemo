require 'rubygems'

desc "Scraping Amazon"
task :scrape_amazon => :environment do
  AmazonPrinter.fewfeatures.find(:all, :conditions => ["created_at > ? and nodetails IS NOT TRUE",1.day.ago]).each { |p|
    p = scrape_details(p)
    p.save
    sleep(1+rand()) #Be nice to Amazon
    sleep(rand()*30) #Be really nice to Amazon!
  }  
end

desc "Scraping Amazon"
task :scrape_printer => :environment do
  #printer = Printer.fewfeatures.find(:first, :order => 'rand()')
  printer = AmazonPrinter.find_by_asin('B00292BV96')
  scrape_details(printer).attributes.each_pair{|k,v| puts k + ": "+ v.to_s}
  puts printer.asin
end

def scrape_details(p)
  require 'webrat'
  puts 'ASIN='+p.asin
  sesh = regularsetup
  begin
  sesh.visit('http://www.amazon.com/o/asin/' + p.asin)
  #fetch 'http://www.amazon.com/o/asin/' + 'B000F005U0'
  #fetch 'http://www.amazon.com/Magicolor-2550-Dn-Color-Laser/dp/tech-data/B000I7VK22/ref=de_a_smtd'
    sesh.click_link('See more technical details')
  rescue
    p.nodetails = true
    return p
  end
  doc = Nokogiri::HTML(sesh.response.body)
  array = doc.css('.content ul li')
  features = {}
  array.each {|i|
    t = i.content.split(': ')
    features[t[0].downcase.tr(' -\(\)_','')]=t[1]
    }
  
  #pp features
  res = []
  features.each {|key, value| 
    next if value.nil?
    if key[/maximumprintspeed/]
      p.ppm = value.to_f unless !p.ppm.nil? && p.ppm >= value.to_i #Keep fastest value
      #puts 'PPM: '+p.ppm.to_s
    end
    if key[/maximumprintspeed/] && key[/colou?r/] #Color
      p.ppmcolor = value.to_f
      #puts 'PPM(Color): '+p.ppmcolor.to_s
    end
    if key[/firstpageoutputtime|timetoprint/]
      p.ttp = value.match(/\d+(.\d+)?/)[0].to_f
      #puts 'TTP:'+p.ttp.to_s
    end
    if key[/sheetcapacity|standardpapercapacity/]
      p.paperinput = value.match(/\d+/)[0].to_i unless !p.paperinput.nil? && p.paperinput > value.to_i #Keep largest value
      #puts 'Paper Input:'+p.paperinput.to_s
    end
    if key[/resolution/] && res.size < 2
      if v = value.match(/(\d,\d{3}|\d+) ?x?X? ?(\d,\d{3}|\d+)?/)
        tmp = v[1,2].compact
        tmp*=2 if tmp.size == 1
        p.resolution = tmp.sort{|a,b| 
          a.gsub!(',','')
          b.gsub!(',','')
          a.to_i < b.to_i ? 1 : a.to_i > b.to_i ? -1 : 0
        }.join(' x ')
        p.resolutionmax = p.resolution.split(' x ')[0]
      end
    end
    if key[/printerinterface/] || (key[/connectivitytechnology/] && value != 'Wired')
      p.connectivity = value
      #puts p.connectivity
    end
    if key[/hardwareplatform/]
      p.platform = value
      #puts 'HW: '+p.platform
    end
    if key[/width/]
      #puts 'Width: ' + p.itemwidth.to_s + ' <> ' + value rescue nil
      p.itemwidth = value.to_f * 100
      #puts 'Width: ' + p.itemwidth.to_s
    end
    if key[/ram/]
      p.systemmemorysize = value.match(/\d+/)[0]
      #puts "RAM" + p.systemmemorysize.to_s
    end
    if key[/printeroutput/]
      p.colorprinter = !value[/(C|c)olou?r/].nil?
      #puts 'Color:' + (p.colorprinter ? 'True' : 'False')
    end
    if key[/scannertype/]
      p.scanner = value[/(N|n)one/].nil?
      #puts 'Scanner:' + (p.scanner ? 'True' : 'False')
    end
    if key[/networkingfeature/]
      p.printserver = !value[/(S|s)erver/].nil?
    end
    if key[/printtechnology/]
      p.colorprinter = value.index(/(B|b)(\/|&)?(W|w)/).nil?
    end
    if key[/duplex/]
      p.duplex = !value.downcase.index('yes').nil?
    end
    if key[/dutycycle/]
      p.dutycycle = value.match(/(\d|,)+/)[0].tr(',','').to_i
    end
  }
  
  p.scrapedat = Time.now
  p
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

# Sets up env and related stuff
def regularsetup
  # Requires.
  require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
  require 'webrat'
  require 'mechanize' # Needed to make Webrat work
  
  Webrat.configure do |conf|
    conf.mode = :mechanize # Can't be rails or Webrat won't work
  end
  sesh = Webrat.session_class.new
  sesh.mechanize.user_agent_alias = 'Mac Safari'
  sesh.mechanize.user_agent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_6; en-us) AppleWebKit/525.27.1 (KHTML, like Gecko) Version/3.2.1 Safari/525.27.1"
  sesh
end
 