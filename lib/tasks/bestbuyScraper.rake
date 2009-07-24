module BestBuyScraper
  
  def clean params
    
    params['maximumresolution'] = to_mpix(parse_res(params['totalpixels'] || params['megapixels']))
    
    params['displaysize'] = get_inches(params['lcdmonitor'] || params['lcdsize'])
    
    atts['listpriceint'] = get_price_i( get_f atts['price'] )
    atts['listpricestr'] = get_price_s(get_f atts['price'])
    
    
    return params
  end

  def scrape_item item
    params = {}
    item.children.each do |el|
      params[just_alphanumeric(no_leading_spaces(el.name))] = no_leading_spaces(el.text) unless el.name == 'ItemSpecs'
    end
    params.merge!( scrape_table item.xpath('FS:ItemSpecs').css('ATT'), 'ATT_NAME', 'ATT_VALUE' )
    item.css('IA').first.attributes.each {|x,y| params[just_alphanumeric(no_leading_spaces(x.to_s))]=no_leading_spaces(y.to_s)}
    
    return params
  end
  
  def filter_items products
    
    ok_category = ["Get Camera and Camcorders products", "Digital Camera Kits", "Stylish & Compact", "DSLR Packages", \
      "DSLR Cameras", "Kids' Cameras", "Basic Point and Shoot", "Waterproof", "Ultra Zoom", "Advanced Compact"]
    # Only digital cameras
    products.delete_if{ |item| 
      item.xpath('FS:CatDept').first.text != "Digital Cameras" or !ok_category.include?(item.css('category').text.to_s.strip )
    }
    return products
  end
  
end

namespace :scrape_bestbuy do
  desc 'asdf'
  task :scrape_all_products => :init do 
     
     possible_params = []
     feeds = ["scrape_me/bestbuy/CameraAndCamcorder.xml", "scrape_me/bestbuy/Computers.xml", "scrape_me/bestbuy/TVandVideo.xml"]
     careful = false
     
     feeds.each do | feed |
       rss = Nokogiri::XML(open(feed))
      
       # Array of rss feed items
       products = filter_items rss.css('item').to_a
       products.each do |item|
          params = scrape_item item
          #possible_params << params.keys
          params.delete_if{|x,y| y.nil?}.each{ |k,v| params.store( @bestbuy_properties[k] || k, v )  }
          params = only_overlapping_atts((clean params), BestBuyCamera)
          x = BestBuyCamera.find_or_initialize_by_skuid(params['skuid'])
          fill_in_all params, x
          sleep(20) if careful
       end
     end
          
     #puts possible_params.flatten.sort.uniq
     
  end
  
  desc 'Init task'
  task :init => :environment do
    require 'Nokogiri'
    
    require 'scraping_helper'
    include ScrapingHelper
    
    require 'conversion_helper'
    include ConversionHelper
    
    require 'database_helper'
    include DatabaseHelper
     
    $model = Camera 
        
    include BestBuyScraper
    @bestbuy_properties = {'title' => 'label', 'mfgpartnum' => 'mpn', 'mfgpartnumber' => 'mpn', \
      'link' => 'detailpageurl'}
  end
  
end