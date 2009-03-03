require 'rubygems'
require 'scrubyt'

desc "Scraping Amazon"
task :scrape_amazon => :environment do
    extractor = Scrubyt::Extractor.define do
      fetch 'http://www.amazon.com/o/asin/B000I7VK22'
      #fetch 'http://www.amazon.com/Magicolor-2550-Dn-Color-Laser/dp/tech-data/B000I7VK22/ref=de_a_smtd'
      click_link 'See more technical details'
      features("Brand Name: Konica", { :generalize => true }) #, :write_text => true 
    end
    product_data_hash = extractor.to_hash
    array = product_data_hash.map{|i| i[:features] if i[:features].index(':')}.compact
    features = {}
    array.each {|i|
      t = i.split(': ')
      features[t[0]]=t[1]
      }
    pp features
    #features.each {|key, value| 
    #  if key[/(M|m)axmimum( |_)?(P|p)rint( |_)?(S|s)peed/]
    #    p.ppm = value.to_i unless !p.ppm.nil? && p.ppm > value.to_i
    #  end
    #}
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
 