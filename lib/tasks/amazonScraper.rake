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
 